import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});
  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  bool _isLogin = true;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Google Sign-In ──────────────────────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled
        setState(() => _googleLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      // Save to SharedPreferences so _AuthGate recognises login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'offline_user_name', user?.displayName ?? 'Plant Lover');
      await prefs.setString('offline_user_email', user?.email ?? '');
      await prefs.setBool('offline_logged_in', true);
      await prefs.setString('auth_provider', 'google');

      if (mounted) _navigateHome(prefs);
    } catch (e) {
      setState(() => _googleLoading = false);
      if (!mounted) return;

      final msg =
          e.toString().contains('network') || e.toString().contains('socket')
              ? 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต กรุณาลองใหม่'
              : 'Google Sign-In ล้มเหลว กรุณาลองใหม่';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ── Local email/password ────────────────────────────────────────────────────
  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก Email และ Password')),
      );
      return;
    }
    if (!_isLogin && name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อ')),
      );
      return;
    }

    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();

    if (_isLogin) {
      final storedEmail = prefs.getString('offline_user_email') ?? '';
      final storedPass = prefs.getString('offline_user_pass') ?? '';

      if (storedEmail.isEmpty) {
        await _saveAndLogin(prefs, email, pass, email.split('@').first);
      } else if (storedEmail == email && storedPass == pass) {
        await _saveAndLogin(prefs, email, pass,
            prefs.getString('offline_user_name') ?? email.split('@').first);
      } else {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email หรือ Password ไม่ถูกต้อง')),
          );
        }
      }
    } else {
      final displayName = name.isNotEmpty ? name : email.split('@').first;
      await _saveAndLogin(prefs, email, pass, displayName);
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_user_name', 'Plant Lover');
    await prefs.setString('offline_user_email', '');
    await prefs.setBool('offline_logged_in', true);
    await prefs.setString('auth_provider', 'guest');
    _navigateHome(prefs);
  }

  Future<void> _saveAndLogin(
    SharedPreferences prefs,
    String email,
    String pass,
    String name,
  ) async {
    await prefs.setString('offline_user_email', email);
    await prefs.setString('offline_user_pass', pass);
    await prefs.setString('offline_user_name', name);
    await prefs.setBool('offline_logged_in', true);
    await prefs.setString('auth_provider', 'local');
    _navigateHome(prefs);
  }

  void _navigateHome(SharedPreferences prefs) {
    if (!mounted) return;
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            onboardingDone ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            'assets/hero/leaves.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: AppColors.primary),
          ),
          // Dark gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.35, 1.0],
                colors: [
                  Color(0x99001A0F),
                  Color(0xBB001A0F),
                  Color(0xF5001A0F),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Logo area ───────────────────────────────────────────────
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                              width: 1.5),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          size: 42,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Plantify',
                        style: GoogleFonts.outfit(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Grow your own sanctuary',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Form area ───────────────────────────────────────────────
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name field (Sign Up only)
                        if (!_isLogin) ...[
                          _buildTextField(
                            controller: _nameCtrl,
                            label: 'Full Name',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Email
                        _buildTextField(
                          controller: _emailCtrl,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),

                        // Password
                        _buildTextField(
                          controller: _passCtrl,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        const SizedBox(height: 24),

                        // Buttons
                        if (_loading || _googleLoading)
                          const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.secondary),
                          )
                        else ...[
                          // Email submit button
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                _isLogin ? 'Log In' : 'Sign Up',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Divider
                          Row(
                            children: [
                              const Expanded(
                                  child: Divider(color: Colors.white24)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('or',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white38, fontSize: 13)),
                              ),
                              const Expanded(
                                  child: Divider(color: Colors.white24)),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ── Google Sign-In button ──────────────────────────
                          _GoogleSignInButton(onTap: _signInWithGoogle),

                          const SizedBox(height: 12),

                          // Continue as Guest button
                          SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _continueAsGuest,
                              icon: const Icon(Icons.person_outline,
                                  size: 20, color: Colors.white70),
                              label: Text(
                                'Continue as Guest',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Toggle login / signup
                          Center(
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _isLogin = !_isLogin),
                              child: RichText(
                                text: TextSpan(
                                  text: _isLogin
                                      ? "Don't have an account? "
                                      : 'Already have an account? ',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: _isLogin ? 'Sign Up' : 'Log In',
                                      style: const TextStyle(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    final obscure = isPassword && !_showPassword;
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14),
        floatingLabelStyle:
            const TextStyle(color: AppColors.secondary, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white38,
                  size: 20,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

// ── Google Sign-In pill button ─────────────────────────────────────────────────
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleSignInButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFDADCE0), width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GoogleSvgLogo(size: 20),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3C4043),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Official Google G logo using the 4-path SVG from Google brand guidelines.
class _GoogleSvgLogo extends StatelessWidget {
  final double size;
  const _GoogleSvgLogo({required this.size});

  static const _svg = '''
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _svg,
      width: size,
      height: size,
    );
  }
}
