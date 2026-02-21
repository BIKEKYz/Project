import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/plant_repository.dart';
import '../../models/plant.dart';
import '../../theme/app_colors.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class _QuizQuestion {
  final Plant correct;
  final List<Plant> options; // 4 items, correct is one of them
  final _QuizType type;

  const _QuizQuestion({
    required this.correct,
    required this.options,
    required this.type,
  });
}

enum _QuizType {
  nameTh, // ดูรูป → ทายชื่อไทย
  nameEn, // ดูรูป → ทายชื่ออังกฤษ
  waterInterval, // รดน้ำทุยกี่วัน?
  light, // ต้นไม้นี้ต้องการแสงระดับใด?
  petSafe, // ปลอดภัยกับสัตว์เลี้ยงมั้ย?
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class PlantQuizScreen extends StatefulWidget {
  final String lang;
  const PlantQuizScreen({super.key, required this.lang});

  @override
  State<PlantQuizScreen> createState() => _PlantQuizScreenState();
}

class _PlantQuizScreenState extends State<PlantQuizScreen>
    with TickerProviderStateMixin {
  final _allPlants = PlantRepository.all();
  late List<_QuizQuestion> _questions;
  int _current = 0;
  int _score = 0;
  int? _selected;
  bool _answered = false;
  bool _started = false;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _shakeCtrl;

  bool get _isTh => widget.lang != 'en';

  @override
  void initState() {
    super.initState();
    _questions = _generateQuestions();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  List<_QuizQuestion> _generateQuestions() {
    final rng = Random();
    final types = _QuizType.values;
    final plants = List<Plant>.from(_allPlants)..shuffle(rng);
    // 10 questions max, one per plant picked randomly
    return plants.take(10).map((plant) {
      final type = types[rng.nextInt(types.length)];
      // build 3 wrong distractors from other plants
      final others = _allPlants.where((p) => p.id != plant.id).toList()
        ..shuffle(rng);
      final distractors = others.take(3).toList();
      final options = [plant, ...distractors]..shuffle(rng);
      return _QuizQuestion(correct: plant, options: options, type: type);
    }).toList();
  }

  String _optionLabel(_QuizType type, Plant p) {
    switch (type) {
      case _QuizType.nameTh:
        return p.nameTh;
      case _QuizType.nameEn:
        return p.nameEn;
      case _QuizType.waterInterval:
        return _isTh
            ? 'รดทุก ${p.waterIntervalDays} วัน'
            : 'Every ${p.waterIntervalDays} days';
      case _QuizType.light:
        return _lightLabel(p.light);
      case _QuizType.petSafe:
        return p.petSafe
            ? (_isTh ? '✅ ปลอดภัย' : '✅ Safe')
            : (_isTh ? '❌ ไม่ปลอดภัย' : '❌ Not safe');
    }
  }

  String _lightLabel(Light l) {
    switch (l) {
      case Light.low:
        return _isTh ? '🌑 แสงน้อย' : '🌑 Low light';
      case Light.medium:
        return _isTh ? '🌤 แสงรำไร' : '🌤 Medium light';
      case Light.bright:
        return _isTh ? '☀️ แสงจัด' : '☀️ Bright light';
    }
  }

  String _questionText(_QuizType type, Plant plant) {
    final name = _isTh ? plant.nameTh : plant.nameEn;
    switch (type) {
      case _QuizType.nameTh:
        return _isTh ? 'ต้นไม้นี้ชื่อว่าอะไร?' : 'What is this plant called?';
      case _QuizType.nameEn:
        return _isTh
            ? 'ต้นไม้นี้ชื่อภาษาอังกฤษว่าอะไร?'
            : 'What is the English name of this plant?';
      case _QuizType.waterInterval:
        return _isTh
            ? '$name ควรรดน้ำทุยกี่วัน?'
            : 'How often should $name be watered?';
      case _QuizType.light:
        return _isTh
            ? '$name ต้องการแสงระดับใด?'
            : 'What light level does $name need?';
      case _QuizType.petSafe:
        return _isTh
            ? '$name ปลอดภัยกับสัตว์เลี้ยงหรือไม่?'
            : 'Is $name safe for pets?';
    }
  }

  bool _isCorrect(_QuizQuestion q, int optionIndex) {
    final chosen = q.options[optionIndex];
    switch (q.type) {
      case _QuizType.nameTh:
      case _QuizType.nameEn:
        return chosen.id == q.correct.id;
      case _QuizType.waterInterval:
        return chosen.waterIntervalDays == q.correct.waterIntervalDays;
      case _QuizType.light:
        return chosen.light == q.correct.light;
      case _QuizType.petSafe:
        return chosen.petSafe == q.correct.petSafe;
    }
  }

  void _answer(int index) {
    if (_answered) return;
    final correct = _isCorrect(_questions[_current], index);
    setState(() {
      _selected = index;
      _answered = true;
      if (correct) _score++;
    });
    if (!correct) _shakeCtrl.forward(from: 0);
  }

  void _next() {
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _selected = null;
        _answered = false;
      });
      _slideCtrl.forward(from: 0);
    } else {
      setState(() => _started = false);
      _showResult();
    }
  }

  void _showResult() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _QuizResultScreen(
          score: _score,
          total: _questions.length,
          lang: widget.lang,
          onRetry: () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PlantQuizScreen(lang: widget.lang),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return _QuizIntroScreen(
        lang: widget.lang,
        onStart: () => setState(() {
          _started = true;
          _slideCtrl.forward(from: 0);
        }),
      );
    }
    final q = _questions[_current];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isTh
              ? 'ข้อ ${_current + 1} / ${_questions.length}'
              : 'Q ${_current + 1} / ${_questions.length}',
          style: GoogleFonts.outfit(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_isTh ? "คะแนน" : "Score"}: $_score',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_current + 1) / _questions.length,
                minHeight: 6,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SlideTransition(
              position: _slideAnim,
              child: _buildQuestion(q),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(_QuizQuestion q) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plant image (always show for name questions)
          if (q.type == _QuizType.nameTh || q.type == _QuizType.nameEn)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  q.correct.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.tertiary.withOpacity(0.3),
                    child: Center(
                      child: Text(
                        '🌿',
                        style: const TextStyle(fontSize: 60),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            // Non-image questions: show plant name as context
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    AppColors.secondary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      q.correct.image,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 70,
                        height: 70,
                        color: AppColors.tertiary,
                        child: const Center(
                            child: Text('🌿', style: TextStyle(fontSize: 32))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isTh ? q.correct.nameTh : q.correct.nameEn,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          q.correct.scientific,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.black45,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Question text
          Text(
            _questionText(q.type, q.correct),
            style: GoogleFonts.notoSansThai(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Options
          ...List.generate(q.options.length, (i) {
            final correct = _isCorrect(q, i);
            final isSelected = _selected == i;

            Color bgColor = Colors.white;
            Color borderColor = Colors.black.withOpacity(0.08);
            Color textColor = const Color(0xFF1A1A1A);
            Widget? trailing;

            if (_answered) {
              if (correct) {
                bgColor = const Color(0xFF4CAF50).withOpacity(0.12);
                borderColor = const Color(0xFF4CAF50);
                textColor = const Color(0xFF2E7D32);
                trailing = const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF4CAF50), size: 22);
              } else if (isSelected) {
                bgColor = AppColors.error.withOpacity(0.10);
                borderColor = AppColors.error;
                textColor = AppColors.error;
                trailing = const Icon(Icons.cancel_rounded,
                    color: AppColors.error, size: 22);
              }
            }

            return GestureDetector(
              onTap: () => _answer(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: !_answered
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _answered && correct
                            ? const Color(0xFF4CAF50).withOpacity(0.15)
                            : _answered && isSelected
                                ? AppColors.error.withOpacity(0.15)
                                : AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + i), // A, B, C, D
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _answered && correct
                                ? const Color(0xFF4CAF50)
                                : _answered && isSelected
                                    ? AppColors.error
                                    : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _optionLabel(q.type, q.options[i]),
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing,
                  ],
                ),
              ),
            );
          }),

          if (_answered) ...[
            const SizedBox(height: 16),
            // Explanation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isTh ? q.correct.description : q.correct.description,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _current < _questions.length - 1
                      ? (_isTh ? 'ข้อถัดไป →' : 'Next →')
                      : (_isTh ? 'ดูผลลัพธ์ 🎉' : 'See Results 🎉'),
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Intro Screen ─────────────────────────────────────────────────────────────

class _QuizIntroScreen extends StatelessWidget {
  final String lang;
  final VoidCallback onStart;
  const _QuizIntroScreen({required this.lang, required this.onStart});

  bool get _isTh => lang != 'en';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primary),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.15),
                        AppColors.secondary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Center(
                    child: Text('🌿', style: TextStyle(fontSize: 48)),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Text(
                  _isTh ? 'ทดสอบความรู้ต้นไม้' : 'Plant Knowledge Quiz',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _isTh
                      ? 'ทดสอบว่าคุณรู้จักต้นไม้แค่ไหน\n10 ข้อ • 4 ตัวเลือก • มีคำอธิบาย'
                      : 'How well do you know your plants?\n10 questions • 4 choices • With explanations',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatPill(emoji: '❓', label: _isTh ? '10 ข้อ' : '10 Q'),
                  _StatPill(
                      emoji: '🎯', label: _isTh ? '4 ตัวเลือก' : '4 choices'),
                  _StatPill(
                      emoji: '🏆', label: _isTh ? 'ดูคะแนน' : 'See score'),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isTh ? 'เริ่มทดสอบ! 🌱' : 'Start Quiz! 🌱',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String emoji;
  final String label;
  const _StatPill({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Result Screen ────────────────────────────────────────────────────────────

class _QuizResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final String lang;
  final VoidCallback onRetry;

  const _QuizResultScreen({
    required this.score,
    required this.total,
    required this.lang,
    required this.onRetry,
  });

  bool get _isTh => lang != 'en';

  (String, String, Color, String) _getGrade() {
    final pct = score / total;
    if (pct >= 0.9) {
      return (
        '🏆',
        _isTh ? 'ปรมาจารย์ต้นไม้!' : 'Plant Master!',
        const Color(0xFFFFB300),
        _isTh
            ? 'ยอดเยี่ยมมาก! คุณรู้จักต้นไม้อย่างลึกซึ้ง'
            : 'Outstanding! You have deep plant knowledge.',
      );
    } else if (pct >= 0.7) {
      return (
        '🌿',
        _isTh ? 'นักปลูกต้นไม้มืออาชีพ' : 'Plant Pro',
        const Color(0xFF4CAF50),
        _isTh
            ? 'เก่งมากเลย! ยังมีเรื่องที่น่าเรียนรู้อีกนะ'
            : 'Great job! There\'s still more to discover.',
      );
    } else if (pct >= 0.5) {
      return (
        '🌱',
        _isTh ? 'มือใหม่ที่มีแวว' : 'Budding Enthusiast',
        const Color(0xFF2196F3),
        _isTh
            ? 'ดีมาก! ลองสำรวจต้นไม้เพิ่มเติมในหน้าสำรวจได้เลย'
            : 'Good progress! Explore more plants to level up.',
      );
    } else {
      return (
        '🌰',
        _isTh ? 'เมล็ดพันธุ์ที่กำลังงอก' : 'Sprouting Seed',
        const Color(0xFF795548),
        _isTh
            ? 'ไม่เป็นไร! ลองไปเรียนรู้ต้นไม้เพิ่มแล้วกลับมาลองใหม่'
            : 'No worries! Learn more about plants and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (emoji, title, color, message) = _getGrade();
    final percent = (score / total * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              // Trophy
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 54)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: GoogleFonts.notoSansThai(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Score card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '$score / $total',
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      _isTh ? '$percent% ถูกต้อง' : '$percent% correct',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: score / total,
                        minHeight: 10,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isTh ? '🔄 ทำซ้ำอีกครั้ง' : '🔄 Try Again',
                    style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                        color: AppColors.primary.withOpacity(0.3), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isTh ? 'กลับหน้าหลัก' : 'Back to Home',
                    style: GoogleFonts.outfit(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
