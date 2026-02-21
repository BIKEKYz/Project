import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardPage(
      emoji: '🌿',
      bg: Color(0xFFE8F5E9),
      accent: Color(0xFF1B4D3E),
      titleTh: 'ยินดีต้อนรับสู่\nPlantify',
      titleEn: 'Welcome to\nPlantify',
      bodyTh:
          'แอปดูแลต้นไม้ที่จะช่วยให้คุณเป็นนักปลูกต้นไม้มืออาชีพ ติดตามสุขภาพ วางแผนการดูแล และเรียนรู้เกี่ยวกับต้นไม้ที่คุณรัก',
      bodyEn:
          'Your plant care companion. Track health, plan care schedules, and learn everything about the plants you love.',
    ),
    _OnboardPage(
      emoji: '💧',
      bg: Color(0xFFE3F2FD),
      accent: Color(0xFF1565C0),
      titleTh: 'ไม่ลืมรดน้ำ\nอีกต่อไป',
      titleEn: 'Never Forget\nto Water',
      bodyTh:
          'ตั้งตารางการรดน้ำ, บันทึก XP ทุกครั้งที่ดูแลต้นไม้ และดูสถิติการดูแลของคุณได้ในหน้า My Garden',
      bodyEn:
          'Set watering schedules, earn XP every time you care for plants, and track all your stats in My Garden.',
    ),
    _OnboardPage(
      emoji: '🌺',
      bg: Color(0xFFFCE4EC),
      accent: Color(0xFFC62828),
      titleTh: 'สำรวจและเรียนรู้\nต้นไม้นับสิบชนิด',
      titleEn: 'Explore & Learn\nDozens of Plants',
      bodyTh:
          'ค้นหาต้นไม้ 24+ ชนิด, ทำ Plant Quiz, เปรียบเทียบต้นไม้แบบ side-by-side และอ่านคู่มือดิน-ปุ๋ยครบถ้วน',
      bodyEn:
          'Discover 24+ plants, take the Plant Quiz, compare plants side-by-side, and read our complete soil & fertilizer guide.',
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_page];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        color: page.bg,
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: _finish,
                    child: Text(
                      'ข้าม',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: page.accent.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _ctrl,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => _PageContent(page: _pages[i]),
                ),
              ),

              // Dots + Button
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? page.accent
                                : page.accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: page.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _page == _pages.length - 1
                              ? 'เริ่มต้นใช้งาน 🌱'
                              : 'ถัดไป',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardPage page;
  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: page.accent.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                page.emoji,
                style: const TextStyle(fontSize: 72),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            page.titleTh,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: page.accent,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),

          // Body
          Text(
            page.bodyTh,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansThai(
              fontSize: 15,
              color: page.accent.withOpacity(0.65),
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPage {
  final String emoji;
  final Color bg;
  final Color accent;
  final String titleTh;
  final String titleEn;
  final String bodyTh;
  final String bodyEn;

  const _OnboardPage({
    required this.emoji,
    required this.bg,
    required this.accent,
    required this.titleTh,
    required this.titleEn,
    required this.bodyTh,
    required this.bodyEn,
  });
}
