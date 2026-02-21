import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── Chat Message Model ───────────────────────────────────────────────────────

enum ChatRole { user, model }

class ChatMessage {
  final ChatRole role;
  final String text;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.role,
    required this.text,
    DateTime? timestamp,
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({String? text, bool? isLoading}) => ChatMessage(
        role: role,
        text: text ?? this.text,
        timestamp: timestamp,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ─── Gemini Chat Service ──────────────────────────────────────────────────────

class GeminiChatService {
  // gemini-2.0-flash: higher quota than flash-lite
  static const _freeModel = 'gemini-2.0-flash';
  static const _proModel = 'gemini-1.5-pro';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // Replace with your actual Gemini API key
  static const _apiKey = 'AIzaSyCeLAf_LliL7i51hpRCruPPP3g_bar8Of0';

  static const _systemPrompt = '''
You are Plantify Bot 🌿, an expert AI plant care assistant for the Plantify app.
You specialize in:
- Plant care advice (watering, fertilizing, pruning, repotting)
- Disease & pest diagnosis and treatment
- Plant identification and recommendations
- Indoor/outdoor growing conditions (light, humidity, soil)
- Thai and tropical plants knowledge

Guidelines:
- Be warm, friendly, and encouraging
- Give practical, actionable advice
- Use emojis occasionally to make responses friendly
- Keep answers concise but complete
- If asked in Thai, respond in Thai
- If asked in English, respond in English
- Always prioritize plant health and user success
''';

  final bool isPro;
  final List<Map<String, dynamic>> _history = [];

  GeminiChatService({this.isPro = false});

  String get _model => isPro ? _proModel : _freeModel;

  /// Send a message and get a streaming-style response
  Future<String> sendMessage(String userMessage) async {
    // Add to history
    _history.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ],
    });

    final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': _systemPrompt}
        ]
      },
      'contents': _history,
      'generationConfig': {
        'temperature': isPro ? 0.8 : 0.7,
        'maxOutputTokens': isPro ? 2048 : 1024,
        'topP': 0.95,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
      ],
    });

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text']
                as String? ??
            'ขอโทษครับ ไม่สามารถตอบได้ในขณะนี้';

        // Add model response to history
        _history.add({
          'role': 'model',
          'parts': [
            {'text': text}
          ],
        });

        return text;
      } else if (response.statusCode == 429) {
        // Rate limited — wait 3 seconds and retry once
        await Future.delayed(const Duration(seconds: 3));
        return await _retryRequest(userMessage);
      } else if (response.statusCode == 403) {
        return '🔑 API Key ไม่ถูกต้อง หรือยังไม่ได้เปิดใช้งาน Gemini API';
      } else if (response.statusCode == 404) {
        // Model not found — fallback to gemini-1.5-flash
        return await _retryWithFallback(userMessage);
      } else {
        // Log body for debugging
        final err = jsonDecode(response.body);
        final msg = err['error']?['message'] ?? response.statusCode.toString();
        return '❌ $msg';
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return '⏱️ หมดเวลาการเชื่อมต่อ กรุณาตรวจสอบอินเทอร์เน็ต';
      }
      return '🌐 ไม่สามารถเชื่อมต่อได้ กรุณาตรวจสอบอินเทอร์เน็ต';
    }
  }

  void clearHistory() => _history.clear();

  /// Retry the same request once (called after 429 + delay)
  Future<String> _retryRequest(String userMessage) async {
    final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');
    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': _systemPrompt}
        ]
      },
      'contents': _history,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
        'topP': 0.95,
      },
    });
    try {
      final response = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text']
                as String? ??
            'ขอโทษครับ ไม่สามารถตอบได้';
        _history.add({
          'role': 'model',
          'parts': [
            {'text': text}
          ],
        });
        return text;
      } else if (response.statusCode == 429) {
        return '⚠️ Rate Limit: API ถูกใช้งานเกินโควต้า กรุณารอ 1 นาทีแล้วลองใหม่';
      } else if (response.statusCode == 403) {
        return '🔑 API Key ไม่ถูกต้อง หรือยังไม่ได้เปิดใช้งาน Gemini API\nไปที่ aistudio.google.com/apikey เพื่อสร้าง Key ใหม่';
      } else {
        // Show the real error from API for debugging
        try {
          final err = jsonDecode(response.body);
          final msg = err['error']?['message'] ?? 'HTTP ${response.statusCode}';
          return '❌ Error ${response.statusCode}: $msg';
        } catch (_) {
          return '❌ HTTP ${response.statusCode}: ${response.body}';
        }
      }
    } catch (_) {
      return '🌐 ไม่สามารถเชื่อมต่อได้ กรุณาตรวจสอบอินเทอร์เน็ต';
    }
  }

  /// Fallback: retry with gemini-1.5-flash
  Future<String> _retryWithFallback(String userMessage) async {
    const fallbackModel = 'gemini-1.5-flash';
    final url =
        Uri.parse('$_baseUrl/$fallbackModel:generateContent?key=$_apiKey');
    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userMessage}
          ]
        }
      ],
      'generationConfig': {'maxOutputTokens': 1024},
    });
    try {
      final response = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates']?[0]?['content']?['parts']?[0]?['text']
                as String? ??
            'ขอโทษครับ ไม่สามารถตอบได้';
      }
      return '❌ ไม่สามารถเชื่อมต่อ Gemini ได้ กรุณาตรวจสอบ API Key';
    } catch (_) {
      return '🌐 ไม่สามารถเชื่อมต่อได้ กรุณาตรวจสอบอินเทอร์เน็ต';
    }
  }
}

// ─── Quick Question Suggestions ───────────────────────────────────────────────

class QuickQuestion {
  final String emoji;
  final String labelTh;
  final String labelEn;
  final String questionTh;
  final String questionEn;

  const QuickQuestion({
    required this.emoji,
    required this.labelTh,
    required this.labelEn,
    required this.questionTh,
    required this.questionEn,
  });

  String label(String lang) => lang == 'en' ? labelEn : labelTh;
  String question(String lang) => lang == 'en' ? questionEn : questionTh;
}

const kQuickQuestions = [
  QuickQuestion(
    emoji: '💧',
    labelTh: 'รดน้ำ',
    labelEn: 'Watering',
    questionTh: 'ควรรดน้ำต้นไม้บ่อยแค่ไหน?',
    questionEn: 'How often should I water my plants?',
  ),
  QuickQuestion(
    emoji: '🌿',
    labelTh: 'ใบเหลือง',
    labelEn: 'Yellow Leaves',
    questionTh: 'ทำไมใบต้นไม้ถึงเหลือง?',
    questionEn: 'Why are my plant leaves turning yellow?',
  ),
  QuickQuestion(
    emoji: '🪲',
    labelTh: 'แมลง',
    labelEn: 'Pests',
    questionTh: 'วิธีกำจัดแมลงในต้นไม้?',
    questionEn: 'How to get rid of plant pests?',
  ),
  QuickQuestion(
    emoji: '☀️',
    labelTh: 'แสงแดด',
    labelEn: 'Sunlight',
    questionTh: 'ต้นไม้ในร่มต้องการแสงแค่ไหน?',
    questionEn: 'How much light do indoor plants need?',
  ),
  QuickQuestion(
    emoji: '🌱',
    labelTh: 'เริ่มต้น',
    labelEn: 'Beginner',
    questionTh: 'ต้นไม้อะไรเหมาะสำหรับมือใหม่?',
    questionEn: 'What plants are best for beginners?',
  ),
  QuickQuestion(
    emoji: '🪴',
    labelTh: 'เปลี่ยนกระถาง',
    labelEn: 'Repotting',
    questionTh: 'เมื่อไหร่ควรเปลี่ยนกระถางต้นไม้?',
    questionEn: 'When should I repot my plant?',
  ),
];
