import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/ai/gemini_chat_service.dart';
import '../../theme/app_colors.dart';

class PlantChatScreen extends StatefulWidget {
  final bool isPro;
  final String lang;

  const PlantChatScreen({
    super.key,
    this.isPro = false,
    this.lang = 'th',
  });

  @override
  State<PlantChatScreen> createState() => _PlantChatScreenState();
}

class _PlantChatScreenState extends State<PlantChatScreen>
    with TickerProviderStateMixin {
  late final GeminiChatService _service;
  final _messages = <ChatMessage>[];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  bool _showQuickQuestions = true;

  @override
  void initState() {
    super.initState();
    _service = GeminiChatService(isPro: widget.isPro);
    // Welcome message
    _messages.add(ChatMessage(
      role: ChatRole.model,
      text: widget.lang == 'en'
          ? 'Hi! 🌿 I\'m Plantify Bot, your personal plant care assistant. Ask me anything about your plants!'
          : 'สวัสดีครับ! 🌿 ผมคือ Plantify Bot ผู้ช่วยดูแลต้นไม้ของคุณ\nถามได้เลยครับ ไม่ว่าจะเรื่องการรดน้ำ ปุ๋ย โรคพืช หรืออะไรก็ตาม!',
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMsg = ChatMessage(role: ChatRole.user, text: text.trim());
    final loadingMsg = ChatMessage(
      role: ChatRole.model,
      text: '',
      isLoading: true,
    );

    setState(() {
      _messages.add(userMsg);
      _messages.add(loadingMsg);
      _isLoading = true;
      _showQuickQuestions = false;
    });
    _controller.clear();
    _scrollToBottom();

    final reply = await _service.sendMessage(text.trim());

    setState(() {
      _messages.removeLast();
      _messages.add(ChatMessage(role: ChatRole.model, text: reply));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F1A14) : const Color(0xFFF5F7F5),
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          // Pro badge banner
          if (widget.isPro) _ProBanner(lang: widget.lang),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                return _MessageBubble(
                  message: msg,
                  isDark: isDark,
                );
              },
            ),
          ),

          // Quick questions
          if (_showQuickQuestions && _messages.length <= 1)
            _QuickQuestionsBar(
              lang: widget.lang,
              isDark: isDark,
              onTap: (q) => _sendMessage(q.question(widget.lang)),
            ),

          // Input bar
          _InputBar(
            controller: _controller,
            isDark: isDark,
            isLoading: _isLoading,
            lang: widget.lang,
            onSend: () => _sendMessage(_controller.text),
            onClear: _messages.length > 1
                ? () {
                    setState(() {
                      _messages.clear();
                      _messages.add(ChatMessage(
                        role: ChatRole.model,
                        text: widget.lang == 'en'
                            ? 'Hi! 🌿 I\'m PlantBot. Ask me anything about your plants!'
                            : 'สวัสดีครับ! 🌿 ถามได้เลยครับ!',
                      ));
                      _showQuickQuestions = true;
                      _service.clearHistory();
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1A2820) : Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? const Color(0xFF7DC99A) : AppColors.primary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🌿', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Plantify Bot',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFD4E8DC)
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                  if (widget.isPro) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PRO',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                widget.lang == 'en'
                    ? 'Plant Care AI Assistant'
                    : 'ผู้ช่วย AI ดูแลต้นไม้',
                style: GoogleFonts.notoSansThai(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF5A7A65)
                      : const Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 4),
          child: Row(
            children: [
              // Online indicator
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                widget.lang == 'en' ? 'Online' : 'ออนไลน์',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Pro Banner ───────────────────────────────────────────────────────────────

class _ProBanner extends StatelessWidget {
  final String lang;
  const _ProBanner({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            lang == 'en'
                ? 'Gemini Pro — Deeper, more detailed answers'
                : 'Gemini Pro — คำตอบที่ลึกและละเอียดกว่า',
            style: GoogleFonts.notoSansThai(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;

  const _MessageBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // Bot avatar
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🌿', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: message.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'คัดลอกแล้ว',
                      style: GoogleFonts.notoSansThai(),
                    ),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser
                      ? AppColors.primary
                      : isDark
                          ? const Color(0xFF1E3028)
                          : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: message.isLoading
                    ? _TypingIndicator()
                    : Text(
                        message.text,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14,
                          height: 1.5,
                          color: isUser
                              ? Colors.white
                              : isDark
                                  ? const Color(0xFFD4E8DC)
                                  : const Color(0xFF1A1A1A),
                        ),
                      ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── Typing Indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 20,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final delay = i * 0.3;
              final t = (_ctrl.value - delay).clamp(0.0, 1.0);
              final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.3, 1.0);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(opacity),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ─── Quick Questions Bar ──────────────────────────────────────────────────────

class _QuickQuestionsBar extends StatelessWidget {
  final String lang;
  final bool isDark;
  final ValueChanged<QuickQuestion> onTap;

  const _QuickQuestionsBar({
    required this.lang,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang == 'en' ? 'Quick questions:' : 'คำถามยอดนิยม:',
            style: GoogleFonts.notoSansThai(
              fontSize: 12,
              color: isDark ? const Color(0xFF5A7A65) : const Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kQuickQuestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final q = kQuickQuestions[i];
                return GestureDetector(
                  onTap: () => onTap(q),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E3028) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2A4035)
                            : AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(q.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 5),
                        Text(
                          q.label(lang),
                          style: GoogleFonts.notoSansThai(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF7DC99A)
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Input Bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final bool isLoading;
  final String lang;
  final VoidCallback onSend;
  final VoidCallback? onClear;

  const _InputBar({
    required this.controller,
    required this.isDark,
    required this.isLoading,
    required this.lang,
    required this.onSend,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2820) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Clear button
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              icon: Icon(
                Icons.refresh_rounded,
                color:
                    isDark ? const Color(0xFF5A7A65) : const Color(0xFFBDBDBD),
                size: 20,
              ),
              tooltip: lang == 'en' ? 'Clear chat' : 'ล้างการสนทนา',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),

          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E3028) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2A4035)
                      : const Color(0xFFE8E8E8),
                ),
              ),
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                style: GoogleFonts.notoSansThai(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFFD4E8DC)
                      : const Color(0xFF1A1A1A),
                ),
                decoration: InputDecoration(
                  hintText: lang == 'en'
                      ? 'Ask about your plants...'
                      : 'ถามเรื่องต้นไม้...',
                  hintStyle: GoogleFonts.notoSansThai(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF5A7A65)
                        : const Color(0xFFBDBDBD),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: isLoading ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isLoading
                    ? AppColors.primary.withOpacity(0.4)
                    : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
