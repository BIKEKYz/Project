// lib/main.dart — Plantify 🪴 (Polished Motion Edition)

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

/// ปรับตรงนี้ถ้าอยากลดการเคลื่อนไหว (true = นิ่งขึ้น)
const bool kSubtleMotion = true;

/// ใช้ GoogleSignIn ตัวเดียวกันทั้งแอป
final GoogleSignIn _google = GoogleSignIn(scopes: <String>['email']);

/* ───────────────────────── Google Sign-In helper ───────────────────────── */

Future<UserCredential> signInWithGoogle() async {
  final GoogleSignInAccount? gUser = await _google.signIn();
  if (gUser == null) {
    throw 'cancelled'; // ผู้ใช้กดยกเลิก
  }
  final GoogleSignInAuthentication auth = await gUser.authentication;

  final OAuthCredential cred = GoogleAuthProvider.credential(
    idToken: auth.idToken,
    accessToken: auth.accessToken,
  );

  final UserCredential userCred =
      await FirebaseAuth.instance.signInWithCredential(cred);

  await userCred.user?.reload();
  return userCred;
}

/* ───────────────────────────────── Avatar ───────────────────────────────── */

class Avatar extends StatelessWidget {
  const Avatar({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // ลองดึงจาก providerData เผื่อช่องหลักยังไม่อัปเดต
    final fromProvider = user?.providerData.isNotEmpty == true
        ? user!.providerData.first.photoURL
        : null;

    String? url = user?.photoURL ?? fromProvider;

    // แนะนำใส่พารามิเตอร์ขนาด
    if (url != null && !url.contains('sz=')) {
      url = '$url?sz=200';
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFE8F0EC),
      backgroundImage: (url != null) ? NetworkImage(url) : null,
      child: (url == null)
          ? Text(
              // ตัวย่อชื่อเป็น fallback
              (user?.displayName?.isNotEmpty ?? false)
                  ? user!.displayName!
                      .trim()
                      .split(' ')
                      .map((e) => e[0])
                      .take(2)
                      .join()
                      .toUpperCase()
                  : '🙂',
              style: const TextStyle(fontWeight: FontWeight.w700),
            )
          : null,
    );
  }
}

/* ============================== App Bootstrap ============================== */

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CondoPlantApp());
}

class CondoPlantApp extends StatelessWidget {
  const CondoPlantApp({super.key});
  static const seed = Color(0xFF2C4A33);

  @override
  Widget build(BuildContext context) {
    final textTheme =
        GoogleFonts.notoSansThaiTextTheme(ThemeData.light().textTheme);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plantify🪴',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF6F7F4),
        textTheme: textTheme,
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/* =============================== Auth (Gate) =============================== */

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  User? _user;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((u) {
      if (!mounted) return;
      setState(() => _user = u);
    });
    _busy = false;
  }

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      if (kIsWeb) {
        // Web ใช้ popup provider
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..setCustomParameters({'prompt': 'select_account'});
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        // Android/iOS ใช้ helper ด้านบน
        await signInWithGoogle();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_user == null) {
      return LoginSignupScreen(onGoogle: _signIn);
    }
    return const SplashScreen();
  }
}

/* ========================== Login / Signup (Tabbed) ========================== */

class LoginSignupScreen extends StatefulWidget {
  final VoidCallback onGoogle;
  const LoginSignupScreen({super.key, required this.onGoogle});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _remember = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _restoreRemembered();
  }

  Future<void> _restoreRemembered() async {
    final sp = await SharedPreferences.getInstance();
    _remember = sp.getBool('remember') ?? false;
    if (_remember) _email.text = sp.getString('remember_email') ?? '';
    if (mounted) setState(() {});
  }

  Future<void> _persistRemembered() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('remember', _remember);
    if (_remember) {
      await sp.setString('remember_email', _email.text.trim());
    } else {
      await sp.remove('remember_email');
    }
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onSubmit() async {
    final email = _email.text.trim();
    final pass = _pass.text;
    if (email.isEmpty || pass.isEmpty) {
      _showMsg('กรุณากรอกอีเมลและรหัสผ่าน');
      return;
    }

    setState(() => _busy = true);
    try {
      if (_tab.index == 0) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );
      }
      await _persistRemembered();
    } on FirebaseAuthException catch (e) {
      _showMsg(e.message ?? 'เกิดข้อผิดพลาดในการยืนยันตัวตน');
    } catch (e) {
      _showMsg('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      _showMsg('กรอกอีเมลก่อนเพื่อส่งลิงก์รีเซ็ตรหัสผ่าน');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showMsg('ส่งอีเมลรีเซ็ตรหัสผ่านแล้ว');
    } on FirebaseAuthException catch (e) {
      _showMsg(e.message ?? 'ส่งอีเมลไม่สำเร็จ');
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final maxCardW = size.width < 420 ? size.width - 24 : 420.0;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _LeafyBackdrop(),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AppHeader(cs: cs),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxCardW),
                  child: Material(
                    color: cs.surface.withOpacity(.86),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: cs.outlineVariant.withOpacity(.25)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TabBar(
                              controller: _tab,
                              indicator: BoxDecoration(
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              labelColor: cs.onPrimary,
                              unselectedLabelColor: cs.onSurfaceVariant,
                              tabs: const [
                                Tab(text: 'Log In'),
                                Tab(text: 'Sign up'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _pass,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              suffixIcon: IconButton(
                                icon: Icon(_obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Checkbox(
                                value: _remember,
                                onChanged: (v) =>
                                    setState(() => _remember = (v ?? false)),
                              ),
                              const Text('Remember me'),
                              const Spacer(),
                              TextButton(
                                onPressed: _forgotPassword,
                                child: const Text('Forgot Password ?'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _busy ? null : _onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5BD0E6),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Text(
                                      _tab.index == 0
                                          ? 'Log In'
                                          : 'Create account',
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _OrDivider(textColor: cs.onSurfaceVariant),
                          const SizedBox(height: 12),
                          GoogleButton(onPressed: widget.onGoogle),
                        ],
                      ),
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
}

/* -------------------------- Small helper widgets -------------------------- */

class _OrDivider extends StatelessWidget {
  final Color? textColor;
  const _OrDivider({this.textColor});

  @override
  Widget build(BuildContext context) {
    final c = textColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Expanded(child: Divider(color: c.withOpacity(.4))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('Or', style: TextStyle(color: c)),
        ),
        Expanded(child: Divider(color: c.withOpacity(.4))),
      ],
    );
  }
}

/// Header โลโก้วงกลม + ชื่อแอป (อยู่นอกการ์ด)
class _AppHeader extends StatelessWidget {
  final ColorScheme cs;
  const _AppHeader({required this.cs});

  @override
  Widget build(BuildContext context) {
    const double logoSize = 56; // ปรับได้
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: logoSize / 2,
          backgroundColor: cs.primaryContainer,
          child: Icon(
            Icons.eco_rounded,
            color: cs.onPrimaryContainer,
            size: logoSize * 0.6,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Plantify',
          style: GoogleFonts.notoSansThai(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: .2,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

/* ───────────────────────────── Backdrop (ใบไม้) ───────────────────────────── */

class _LeafyBackdrop extends StatelessWidget {
  const _LeafyBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/hero/leaves.jpg', // มี fallback กัน error หากไม่มีไฟล์
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFDDEFE3), Color(0xFFBFD8C8)],
                ),
              ),
            );
          },
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: []),
          ),
          foregroundDecoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(.55),
                Colors.white.withOpacity(.35),
                Colors.white.withOpacity(.25),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ],
    );
  }
}

/* ================================= Splash ================================= */

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = CurvedAnimation(parent: _ac, curve: Curves.easeOutBack);
    if (kSubtleMotion) _ac.forward();
    Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) => kSubtleMotion
              ? FadeTransition(opacity: anim, child: child)
              : child,
        ),
      );
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final logo = Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Icon(Icons.eco_rounded, size: 64, color: cs.onPrimaryContainer),
    );
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child:
            kSubtleMotion ? ScaleTransition(scale: _scale, child: logo) : logo,
      ),
    );
  }
}

/* ================================ Domain ================================= */

enum Light { low, medium, bright }

enum SizeClass { tiny, small, medium }

enum Difficulty { easy, medium, hard }

enum Aspect { north, east, south, west }

/// แม็ปทิศหน้าต่าง → ระดับแสงที่ "เหมาะสม"
Set<Light> lightsForAspect(Aspect a) {
  switch (a) {
    case Aspect.north:
      return {Light.low, Light.medium}; // ทิศเหนือ แดดน้อย
    case Aspect.east:
      return {Light.medium, Light.bright}; // เช้า แดดอ่อน-รำไรถึงสว่าง
    case Aspect.south:
      return {Light.bright, Light.medium}; // ใต้ แดดจัด
    case Aspect.west:
      return {Light.bright, Light.medium}; // บ่าย แดดแรง
  }
}

/// ชื่อไทยของทิศ (ไว้ใช้บน UI)
String aspectTH(Aspect? a) {
  if (a == null) return 'ทั้งหมด';
  switch (a) {
    case Aspect.north:
      return 'ทิศเหนือ';
    case Aspect.east:
      return 'ทิศตะวันออก';
    case Aspect.south:
      return 'ทิศใต้';
    case Aspect.west:
      return 'ทิศตะวันตก';
  }
}

class Plant {
  final String id;
  final String nameTh;
  final String nameEn;
  final String scientific;
  final SizeClass size;
  final Light light;
  final Difficulty difficulty;
  final bool petSafe;
  final bool airPurifying;
  final int waterIntervalDays;
  final List<String> tags;
  final String image;

  const Plant({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.scientific,
    required this.size,
    required this.light,
    required this.difficulty,
    required this.petSafe,
    required this.airPurifying,
    required this.waterIntervalDays,
    required this.tags,
    required this.image,
    required String description, // รับไว้เพื่อความเข้ากันได้ (ยังไม่แสดงผล)
  });
}

/* =============================== Repository =============================== */

class PlantRepository {
  static List<Plant> all() => const [
        Plant(
          id: 'sansevieria',
          nameTh: 'ลิ้นมังกรจิ๋ว',
          nameEn: 'Dwarf Snake Plant',
          scientific: 'Sansevieria trifasciata “Hahnii”',
          size: SizeClass.small,
          light: Light.low,
          difficulty: Difficulty.easy,
          petSafe: false,
          airPurifying: true,
          waterIntervalDays: 10,
          tags: ['ทนแห้ง', 'ดูแลง่าย', 'ฟอกอากาศ'],
          description:
              'ทนทาน แสงน้อยก็อยู่ได้ เหมาะคอนโดที่แดดเข้าไม่มาก รดน้ำน้อยและอย่าขังน้ำในกระถาง.',
          image: 'assets/images/sanseviera.jpg',
        ),
        Plant(
          id: 'pothos',
          nameTh: 'พลูด่าง',
          nameEn: 'Pothos',
          scientific: 'Epipremnum aureum',
          size: SizeClass.small,
          light: Light.medium,
          difficulty: Difficulty.easy,
          petSafe: false,
          airPurifying: true,
          waterIntervalDays: 5,
          tags: ['เลื้อย', 'ดูแลง่าย', 'ฟอกอากาศ'],
          description:
              'ไม้เลื้อยยอดนิยม โตไว ทน ทิ้งช่วงให้หน้าดินแห้งค่อยรด เหมาะแขวนหรือวางชั้น.',
          image: 'assets/images/pothos.jpeg',
        ),
        Plant(
          id: 'peace_lily',
          nameTh: 'เดหลี',
          nameEn: 'Peace Lily',
          scientific: 'Spathiphyllum wallisii',
          size: SizeClass.medium,
          light: Light.low,
          difficulty: Difficulty.medium,
          petSafe: false,
          airPurifying: true,
          waterIntervalDays: 4,
          tags: ['ออกดอก', 'ชอบชื้น', 'ฟอกอากาศ'],
          description:
              'ชอบความชื้นสม่ำเสมอ ไม่ต้องโดนแดดตรง ๆ ดอกสีขาวช่วยแต่งห้องให้ดูสะอาดตา.',
          image: "assets/images/zz.jpeg",
        ),
      ];

  static const String description = '—';
}

/* ======================== Persistence (Favorites) ======================== */

class FavoriteStore with ChangeNotifier {
  static const _key = 'favorite_ids';
  final Set<String> _ids = {};
  bool _ready = false;

  bool get isReady => _ready;
  bool isFavorite(String id) => _ids.contains(id);
  int get count => _ids.length;

  FavoriteStore() {
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_key) ?? [];
    _ids
      ..clear()
      ..addAll(list);
    _ready = true;
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    if (_ids.contains(id)) {
      _ids.remove(id);
    } else {
      _ids.add(id);
    }
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_key, _ids.toList());
  }
}

/* ============================= Watering Store ============================= */

class WateringStore with ChangeNotifier {
  static const _keyPrefix = 'water_last_';
  final Map<String, DateTime> _last = {};
  bool _ready = false;

  bool get isReady => _ready;

  WateringStore() {
    _loadAll();
  }

  DateTime lastOf(String plantId) {
    // ถ้ายังไม่เคยรด: ถือว่าเพิ่งรดวันนี้ เพื่อ UX ที่ดีกับผู้ใช้ใหม่
    return _last[plantId] ?? DateTime.now();
  }

  Future<void> setNow(String plantId) async {
    _last[plantId] = DateTime.now();
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
        '$_keyPrefix$plantId', _last[plantId]!.toIso8601String());
  }

  Future<void> _loadAll() async {
    final sp = await SharedPreferences.getInstance();
    for (final p in PlantRepository.all()) {
      final raw = sp.getString('$_keyPrefix${p.id}');
      if (raw != null) {
        _last[p.id] = DateTime.tryParse(raw) ?? DateTime.now();
      }
    }
    _ready = true;
    notifyListeners();
  }
}

/* ============================ Filters / State ============================ */

class PlantFilter with ChangeNotifier {
  String query = '';
  Light? light;
  bool onlyPetSafe = false;
  bool onlyAirPurifying = false;
  Difficulty? difficulty;

  // ตัวกรองทิศหน้าต่าง/แดด
  Aspect? aspect;

  void clear() {
    query = '';
    light = null;
    difficulty = null;
    onlyPetSafe = false;
    onlyAirPurifying = false;
    aspect = null; // เคลียร์ทิศด้วย
    notifyListeners();
  }

  void setQuery(String q) {
    query = q.trim();
    notifyListeners();
  }

  void setLight(Light? l) {
    light = l;
    notifyListeners();
  }

  void setDifficulty(Difficulty? d) {
    difficulty = d;
    notifyListeners();
  }

  void togglePetSafe() {
    onlyPetSafe = !onlyPetSafe;
    notifyListeners();
  }

  void toggleAirPurifying() {
    onlyAirPurifying = !onlyAirPurifying;
    notifyListeners();
  }

  // ตั้งค่าทิศ
  void setAspect(Aspect? a) {
    aspect = a;
    notifyListeners();
  }

  List<Plant> apply(List<Plant> src) {
    return src.where((p) {
      final q = query.toLowerCase();

      final okQ = q.isEmpty ||
          p.nameTh.toLowerCase().contains(q) ||
          p.nameEn.toLowerCase().contains(q) ||
          p.scientific.toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q));

      final okLight = light == null || p.light == light;
      final okDiff = difficulty == null || p.difficulty == difficulty;
      final okPet = !onlyPetSafe || p.petSafe;
      final okAir = !onlyAirPurifying || p.airPurifying;

      // ถ้าเลือกทิศ → เช็กว่าระดับแสงของต้นไม้อยู่ในช่วงที่เหมาะกับทิศนั้น
      final okAspect =
          aspect == null || lightsForAspect(aspect!).contains(p.light);

      return okQ && okLight && okDiff && okPet && okAir && okAspect;
    }).toList();
  }
}

/* ================================= Home ================================= */

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FavoriteStore fav = FavoriteStore();
  final PlantFilter filter = PlantFilter();
  final WateringStore water = WateringStore();
  final all = PlantRepository.all();
  User? user;

  @override
  void initState() {
    super.initState();
    fav.addListener(_onAny);
    filter.addListener(_onAny);
    water.addListener(_onAny);
    user = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.userChanges().listen((u) {
      if (!mounted) return;
      setState(() => user = u);
    });
  }

  @override
  void dispose() {
    fav.removeListener(_onAny);
    filter.removeListener(_onAny);
    water.removeListener(_onAny);
    super.dispose();
  }

  void _onAny() => setState(() {});

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!kIsWeb) {
      await _google.signOut();
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = filter.apply(all);
    final showEmpty = filtered.isEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primaryContainer,
                boxShadow: [
                  BoxShadow(color: cs.primary.withOpacity(.25), blurRadius: 12)
                ],
              ),
              child: Icon(Icons.eco_rounded, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 10),
            Text('Plantify',
                style: GoogleFonts.notoSansThai(
                  fontWeight: FontWeight.w800,
                  letterSpacing: .3,
                  color: cs.primary,
                  fontSize: 20,
                )),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'บัญชีของฉัน',
            onPressed: () => _openAccountSheet(context, user),
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: cs.primaryContainer,
              backgroundImage:
                  user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFEFF7F0),
                    const Color(0xFFF6FBF7),
                    const Color(0xFFFDFEFE)
                  ],
                ),
              ),
            ),
          ),
          Positioned(
              top: -60,
              right: -30,
              child: _GlowBlob(color: cs.primary.withOpacity(.15), size: 180)),
          Positioned(
              top: 120,
              left: -20,
              child:
                  _GlowBlob(color: cs.secondary.withOpacity(.12), size: 140)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  _HeroHeader(
                    userName: user?.displayName ?? 'ชาวสวนเมือง',
                    favCount: fav.count,
                  ),

                  const SizedBox(height: 12),

                  // 👉 แถบเรียกแบบสอบถามไลฟ์สไตล์
                  _LifestyleQuizCallout(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RecommendationScreen(
                            allPlants: all,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // กล่อง search เดิม
                  Material(
                    color: cs.surface,
                    elevation: 2,
                    borderRadius: BorderRadius.circular(14),
                    shadowColor: Colors.black.withOpacity(.05),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.search, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              onChanged: filter.setQuery,
                              decoration: const InputDecoration(
                                hintText:
                                    'ค้นหา: ชื่อไทย/อังกฤษ/วิทยาศาสตร์/แท็ก',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () => _openFilterSheet(context, filter),
                            icon: const Icon(Icons.tune_rounded, size: 18),
                            label: const Text('กรอง'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _QuickFilters(filter: filter),
                  const SizedBox(height: 10),
                  Expanded(
                    child: showEmpty
                        ? _EmptyState(onClear: filter.clear)
                        : GridView.builder(
                            padding: const EdgeInsets.only(bottom: 16, top: 4),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: .9,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              const double start = 0.92;
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: start, end: 1.0),
                                duration: const Duration(milliseconds: 340),
                                curve: Curves.easeOutCubic,
                                builder: (c, scale, child) {
                                  final opacity =
                                      ((scale - start) / (1.0 - start))
                                          .clamp(0.0, 1.0);
                                  return Transform.scale(
                                    scale: scale,
                                    child: Opacity(
                                      opacity: opacity,
                                      child: child,
                                    ),
                                  );
                                },
                                child: _TactileCard(
                                  child: _PlantCard(
                                    plant: filtered[i],
                                    fav: fav,
                                    water: water,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: FilledButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAccountSheet(BuildContext context, User? user) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: cs.primaryContainer,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null ? const Icon(Icons.person) : null,
              ),
              title: Text(user?.displayName ?? 'ผู้ใช้ Plantify'),
              subtitle: Text(user?.email ?? '-'),
            ),
            const SizedBox(height: 8),
            const ListTile(
              leading: Icon(Icons.cloud_done_rounded),
              title: Text('ซิงก์รายการโปรด & การตั้งค่า'),
              subtitle: Text('พร้อมใช้งานเมื่อเชื่อมต่อบัญชี'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                label: const Text('ปิด'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LifestyleQuizCallout extends StatelessWidget {
  final VoidCallback onTap;
  const _LifestyleQuizCallout({Key? key, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.quiz_rounded,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'แบบสอบถามแนะนำต้นไม้',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'กรอกไลฟ์สไตล์สั้น ๆ แล้วให้ระบบช่วยเลือกต้นไม้ที่เหมาะกับคุณ',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================================ Widgets ================================ */

class _SearchBar extends StatelessWidget {
  final PlantFilter filter;
  const _SearchBar({required this.filter});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: filter.setQuery,
            decoration: const InputDecoration(
              hintText: 'ค้นหา: ชื่อไทย/อังกฤษ/วิทยาศาสตร์/แท็ก',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _openFilterSheet(context, filter),
            icon: const Icon(Icons.tune_rounded),
            label: const Text('กรอง'),
          ),
        ),
      ],
    );
  }
}

class _QuickFilters extends StatelessWidget {
  final PlantFilter filter;
  const _QuickFilters({required this.filter});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget buildToggle({
      required bool active,
      required String label,
      required VoidCallback onTap,
      IconData? icon,
    }) {
      return ChoiceChip(
        selected: active,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              SizedBox(width: 6),
            ],
            Text(label),
          ],
        ),
        onSelected: (_) => onTap(),
        selectedColor: cs.secondaryContainer,
        backgroundColor: const Color(0xFFEFF2EA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          buildToggle(
            active: filter.onlyPetSafe,
            label: 'ปลอดภัยสัตว์เลี้ยง',
            icon: Icons.pets_rounded,
            onTap: filter.togglePetSafe,
          ),
          const SizedBox(width: 8),
          buildToggle(
            active: filter.onlyAirPurifying,
            label: 'ฟอกอากาศ',
            icon: Icons.air_rounded,
            onTap: filter.toggleAirPurifying,
          ),
          const SizedBox(width: 8),

          // 👉 ปุ่มเลือกทิศที่เพิ่มมา
          _AspectPill(filter: filter),

          const SizedBox(width: 8),
          _LightPill(filter: filter),
          const SizedBox(width: 8),
          _DiffPill(filter: filter),
        ],
      ),
    );
  }
}

class _AspectPill extends StatelessWidget {
  final PlantFilter filter;
  const _AspectPill({required this.filter});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Aspect?>(
      tooltip: 'กรองตามทิศหน้าต่าง/แดดเข้าห้อง',
      onSelected: filter.setAspect,
      itemBuilder: (_) => const [
        PopupMenuItem(value: null, child: Text('ทั้งหมด')),
        PopupMenuItem(value: Aspect.north, child: Text('ทิศเหนือ')),
        PopupMenuItem(value: Aspect.east, child: Text('ทิศตะวันออก')),
        PopupMenuItem(value: Aspect.south, child: Text('ทิศใต้')),
        PopupMenuItem(value: Aspect.west, child: Text('ทิศตะวันตก')),
      ],
      child: const Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore_outlined, size: 18),
            SizedBox(width: 6),
            Text('ทิศ'),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _LightPill extends StatelessWidget {
  final PlantFilter filter;
  const _LightPill({required this.filter});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Light?>(
      tooltip: 'กรองตามแสง',
      onSelected: filter.setLight,
      itemBuilder: (_) => const [
        PopupMenuItem(value: null, child: Text('ทั้งหมด')),
        PopupMenuItem(value: Light.low, child: Text('แสงน้อย')),
        PopupMenuItem(value: Light.medium, child: Text('แสงรำไร')),
        PopupMenuItem(value: Light.bright, child: Text('แสงสว่างจัด')),
      ],
      child: const Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wb_sunny_outlined, size: 18),
            SizedBox(width: 6),
            Text('แสง'),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DiffPill extends StatelessWidget {
  final PlantFilter filter;
  const _DiffPill({required this.filter});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Difficulty?>(
      tooltip: 'กรองตามความยาก',
      onSelected: filter.setDifficulty,
      itemBuilder: (context) => const [
        PopupMenuItem<Difficulty?>(value: null, child: Text('ทั้งหมด')),
        PopupMenuItem<Difficulty?>(value: Difficulty.easy, child: Text('ง่าย')),
        PopupMenuItem<Difficulty?>(
            value: Difficulty.medium, child: Text('ปานกลาง')),
        PopupMenuItem<Difficulty?>(value: Difficulty.hard, child: Text('ยาก')),
      ],
      child: const Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_florist_outlined, size: 18),
            SizedBox(width: 6),
            Text('ระดับดูแล'),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _PlantGrid extends StatelessWidget {
  final List<Plant> plants;
  final FavoriteStore fav;
  final WateringStore water;
  const _PlantGrid(
      {required this.plants, required this.fav, required this.water});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size.width;
    final cross = media >= 1100
        ? 4
        : media >= 760
            ? 3
            : 2;

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: .88,
      ),
      itemCount: plants.length,
      itemBuilder: (context, i) => _TactileCard(
        child: _PlantCard(plant: plants[i], fav: fav, water: water),
      ),
    );
  }
}

/// การ์ดสัมผัส: ยก elevation นิดๆ และ scale 0.98 ตอนกด
class _TactileCard extends StatefulWidget {
  final Widget child;
  const _TactileCard({required this.child});
  @override
  State<_TactileCard> createState() => _TactileCardState();
}

class _TactileCardState extends State<_TactileCard> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final scale = (_down && kSubtleMotion) ? 0.98 : 1.0;
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            boxShadow: [
              if (_down && kSubtleMotion)
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/* ====================== Staggered appear animation helper ===================== */

class DelayedScaleIn extends StatefulWidget {
  const DelayedScaleIn({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 250),
    this.duration = const Duration(milliseconds: 350),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<DelayedScaleIn> createState() => _DelayedScaleInState();
}

class _DelayedScaleInState extends State<DelayedScaleIn> {
  bool _start = false;

  @override
  void initState() {
    super.initState();
    if (kSubtleMotion) {
      Future.delayed(widget.delay, () {
        if (mounted) setState(() => _start = true);
      });
    } else {
      _start = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.92, end: _start ? 1.0 : 0.92),
      builder: (c, scale, child) => Transform.scale(
        scale: scale,
        child: Opacity(opacity: (scale - .9).clamp(0, 1), child: child),
      ),
      child: widget.child,
    );
  }
}

/* ================================ Cards ================================ */

class _PlantCard extends StatelessWidget {
  final Plant plant;
  final FavoriteStore fav;
  final WateringStore water;
  const _PlantCard(
      {required this.plant, required this.fav, required this.water});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFav = fav.isFavorite(plant.id);

    // --- Watering state
    final last = water.lastOf(plant.id);
    final dLeft = daysUntilNextWater(last, plant.waterIntervalDays);
    final pct = waterProgress(last, plant.waterIntervalDays);
    final dueDate = DateTime(last.year, last.month, last.day)
        .add(Duration(days: plant.waterIntervalDays));

    final chipColor = dLeft >= 2
        ? cs.surfaceContainerHighest
        : dLeft >= 0
            ? cs.secondaryContainer
            : Colors.red.withOpacity(.12);

    return Card(
      elevation: 0,
      color: cs.surface.withOpacity(.72),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 280),
              pageBuilder: (_, __, ___) =>
                  PlantDetailScreen(plant: plant, fav: fav, water: water),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant.withOpacity(.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // ==== รูป + Hero ====
                  Hero(
                    tag: 'plant:${plant.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        plant.image,
                        height: 84,
                        width: 84,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _AvatarLetter(id: plant.id),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plant.nameTh,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text(plant.nameEn,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: isFav ? 'นำออกจากโปรด' : 'เพิ่มรายการโปรด',
                    style: IconButton.styleFrom(
                      backgroundColor: isFav
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      shape: const CircleBorder(),
                    ),
                    onPressed: () => fav.toggle(plant.id),
                    icon: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFav ? cs.primary : cs.onSurface),
                  )
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: -8,
                children: [
                  _Tag(
                      icon: Icons.wb_sunny_outlined,
                      text: _lightText(plant.light)),
                  _Tag(
                      icon: Icons.water_drop_outlined,
                      text: 'ทุก ${plant.waterIntervalDays} วัน'),
                  if (plant.airPurifying)
                    const _Tag(icon: Icons.air_rounded, text: 'ฟอกอากาศ'),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('รดน้ำครั้งถัดไป',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                      const Spacer(),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: chipColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${describeWaterDueTH(dLeft)} • ${_fmtDateTH(dueDate)}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(8),
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      Color.lerp(cs.secondary, Colors.redAccent, pct * .8)!,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        await water.setNow(plant.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('บันทึกว่า “รดน้ำแล้ว”')),
                          );
                        }
                      },
                      icon: const Icon(Icons.water_drop_rounded),
                      label: const Text('รดน้ำแล้ว'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _lightText(Light l) => l == Light.low
      ? 'แสงน้อย'
      : l == Light.medium
          ? 'แสงรำไร'
          : 'แสงสว่างจัด';
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Tag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Chip(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: cs.surfaceContainerHighest,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Chip(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: cs.surfaceContainerHighest,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }
}

class _AvatarLetter extends StatelessWidget {
  final String id;
  const _AvatarLetter({required this.id});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final letter = (id.isNotEmpty ? id[0] : '?').toUpperCase();
    return Container(
      height: 84,
      width: 84,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primaryContainer, cs.secondaryContainer],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(
        child: Text(
          letter,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: cs.onPrimaryContainer, fontSize: 36),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptyState({required this.onClear});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: cs.outline),
          const SizedBox(height: 12),
          Text('ไม่พบผลลัพธ์ที่ตรงเงื่อนไข',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'ลองเปลี่ยนตัวกรองหรือเคลียร์ทั้งหมด',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.outline),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onClear, child: const Text('ล้างตัวกรอง')),
        ],
      ),
    );
  }
}

/* ============================== Filter Sheet ============================== */

class _FilterSheet extends StatelessWidget {
  final PlantFilter filter;
  const _FilterSheet({required this.filter});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget section(String title, Widget child) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: cs.onSurface),
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        );

    ChoiceChip cchip(String label, bool sel, VoidCallback onTap) => ChoiceChip(
          label: Text(label),
          selected: sel,
          onSelected: (_) => onTap(),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ───────── แสง ─────────
          section(
            'แสง',
            Wrap(
              spacing: 8,
              children: [
                cchip('ทั้งหมด', filter.light == null,
                    () => filter.setLight(null)),
                cchip('แสงน้อย', filter.light == Light.low,
                    () => filter.setLight(Light.low)),
                cchip('แสงรำไร', filter.light == Light.medium,
                    () => filter.setLight(Light.medium)),
                cchip('แสงสว่างจัด', filter.light == Light.bright,
                    () => filter.setLight(Light.bright)),
              ],
            ),
          ),

          // ───────── ทิศหน้าต่าง/แดด ─────────
          section(
            'ทิศหน้าต่าง/แดดเข้าห้อง',
            Wrap(
              spacing: 8,
              children: [
                cchip('ทั้งหมด', filter.aspect == null,
                    () => filter.setAspect(null)),
                cchip('ทิศเหนือ', filter.aspect == Aspect.north,
                    () => filter.setAspect(Aspect.north)),
                cchip('ทิศตะวันออก', filter.aspect == Aspect.east,
                    () => filter.setAspect(Aspect.east)),
                cchip('ทิศใต้', filter.aspect == Aspect.south,
                    () => filter.setAspect(Aspect.south)),
                cchip('ทิศตะวันตก', filter.aspect == Aspect.west,
                    () => filter.setAspect(Aspect.west)),
              ],
            ),
          ),

          // ───────── ระดับดูแล ─────────
          section(
            'ระดับดูแล',
            Wrap(
              spacing: 8,
              children: [
                cchip('ทั้งหมด', filter.difficulty == null,
                    () => filter.setDifficulty(null)),
                cchip('ง่าย', filter.difficulty == Difficulty.easy,
                    () => filter.setDifficulty(Difficulty.easy)),
                cchip('ปานกลาง', filter.difficulty == Difficulty.medium,
                    () => filter.setDifficulty(Difficulty.medium)),
                cchip('ยาก', filter.difficulty == Difficulty.hard,
                    () => filter.setDifficulty(Difficulty.hard)),
              ],
            ),
          ),

          // ───────── คุณสมบัติ ─────────
          section(
            'คุณสมบัติ',
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('ปลอดภัยสัตว์เลี้ยง'),
                  selected: filter.onlyPetSafe,
                  onSelected: (_) => filter.togglePetSafe(),
                  avatar: const Icon(Icons.pets_rounded, size: 18),
                ),
                FilterChip(
                  label: const Text('ฟอกอากาศ'),
                  selected: filter.onlyAirPurifying,
                  onSelected: (_) => filter.toggleAirPurifying(),
                  avatar: const Icon(Icons.air_rounded, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: filter.clear,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('ล้างทั้งหมด'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('เสร็จสิ้น'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ================================ Detail ================================ */

class PlantDetailScreen extends StatelessWidget {
  final Plant plant;
  final FavoriteStore fav;
  final WateringStore water;
  const PlantDetailScreen(
      {super.key, required this.plant, required this.fav, required this.water});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget infoTile(IconData icon, String title, String value) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(value, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final last = water.lastOf(plant.id);
    final left = daysUntilNextWater(last, plant.waterIntervalDays);

    return Scaffold(
      appBar: AppBar(
        title: Text(plant.nameTh),
        actions: [
          IconButton(
            tooltip:
                fav.isFavorite(plant.id) ? 'นำออกจากโปรด' : 'เพิ่มรายการโปรด',
            onPressed: () => fav.toggle(plant.id),
            icon: Icon(
              fav.isFavorite(plant.id)
                  ? Icons.favorite_rounded
                  : Icons.favorite_outline_rounded,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              Hero(
                tag: 'plant:${plant.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    plant.image,
                    height: 84,
                    width: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _AvatarLetter(id: plant.id),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plant.nameEn,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      plant.scientific,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: -8,
                      children: [
                        _Pill(
                            icon: Icons.wb_sunny_outlined,
                            text: _lightText(plant.light)),
                        _Pill(
                            icon: Icons.water_drop_outlined,
                            text: 'ทุก ${plant.waterIntervalDays} วัน'),
                        _Pill(
                            icon: Icons.straighten_rounded,
                            text: _sizeText(plant.size)),
                        _Pill(
                            icon: Icons.speed_rounded,
                            text: _diffText(plant.difficulty)),
                        if (plant.airPurifying)
                          const _Pill(
                              icon: Icons.air_rounded, text: 'ฟอกอากาศ'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('รายละเอียด', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(PlantRepository.description),
          const SizedBox(height: 16),
          Text('คำแนะนำดูแล', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.8,
            ),
            children: [
              infoTile(Icons.wb_sunny_outlined, 'แสง', _lightText(plant.light)),
              infoTile(Icons.water_drop_outlined, 'รดน้ำ',
                  'ประมาณทุก ${plant.waterIntervalDays} วัน'),
              infoTile(Icons.grass_rounded, 'ขนาด', _sizeText(plant.size)),
              infoTile(
                  Icons.speed_rounded, 'ความยาก', _diffText(plant.difficulty)),
            ],
          ),
          const SizedBox(height: 16),
          Text('แท็ก', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: plant.tags.map((t) => Chip(label: Text(t))).toList(),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () => _showWateringTip(context, plant),
            icon: const Icon(Icons.tips_and_updates_rounded),
            label: const Text('ทริคการรดน้ำแบบคอนโด'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await water.setNow(plant.id);
                    if (context.mounted) {
                      final left2 = daysUntilNextWater(
                        water.lastOf(plant.id),
                        plant.waterIntervalDays,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'บันทึกแล้ว • ${describeWaterDueTH(left2)}')),
                      );
                    }
                  },
                  icon: const Icon(Icons.water_drop_rounded),
                  label: const Text('รดน้ำแล้ว'),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  describeWaterDueTH(left),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _lightText(Light l) => l == Light.low
      ? 'แสงน้อย'
      : l == Light.medium
          ? 'แสงรำไร'
          : 'แสงสว่างจัด';
  static String _sizeText(SizeClass s) => s == SizeClass.tiny
      ? 'จิ๋ว'
      : s == SizeClass.small
          ? 'เล็ก'
          : 'กลาง';
  static String _diffText(Difficulty d) => d == Difficulty.easy
      ? 'ง่าย'
      : d == Difficulty.medium
          ? 'ปานกลาง'
          : 'ยาก';

  void _showWateringTip(BuildContext context, Plant p) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('รดน้ำให้พอดีกับ "${p.nameTh}"',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              '• ตรวจดิน: จิ้มลงไป ~2 ซม. ถ้าแห้งค่อยรด\n'
              '• ปริมาณ: รดให้ชุ่มแล้วปล่อยน้ำส่วนเกินไหลออกจากก้นกระถาง\n'
              '• แสง-ลม: ถ้าอากาศแห้ง/แสงจัด อาจต้องรดถี่ขึ้นเล็กน้อย\n'
              '• ระวัง: อย่าขังน้ำ โดยเฉพาะกลุ่มอวบน้ำ/ลิ้นมังกร/กวักมรกต',
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('โอเค เข้าใจแล้ว'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================= Google Button (Bouncy) ============================= */

class GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  const GoogleButton({
    super.key,
    required this.onPressed,
    this.label = 'ลงชื่อเข้าใช้ด้วย Google',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const lightBorder = Color(0xFFDADCE0);
    const darkBorder = Color(0xFF5F6368);
    const lightText = Color(0xFF3C4043);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Material(
        color: isDark ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: isDark ? darkBorder : lightBorder),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/google_g.png',
                  width: 18,
                  height: 18,
                  errorBuilder: (c, e, s) => Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: lightBorder),
                    ),
                    child: const Text(
                      'G',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : lightText,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ========================== Hero / Glow helper ========================== */

class _HeroHeader extends StatelessWidget {
  final String userName;
  final int favCount;
  const _HeroHeader({required this.userName, required this.favCount});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primaryContainer.withOpacity(.9),
            cs.secondaryContainer.withOpacity(.9)
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: cs.onPrimaryContainer.withOpacity(.08),
            child: const Icon(Icons.eco_rounded, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('สวัสดี, $userName 👋',
                    style: GoogleFonts.notoSansThai(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: cs.onPrimaryContainer)),
                const SizedBox(height: 4),
                Text(
                    'เลือกต้นไม้ให้เข้ากับไลฟ์สไตล์ของคุณ แล้วดูแลได้ง่ายขึ้นวันนี้',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onPrimaryContainer.withOpacity(.85))),
              ],
            ),
          ),
          _MetricChip(
              icon: Icons.favorite_rounded,
              label: 'รายการโปรด',
              value: favCount.toString()),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetricChip(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 6),
          Text('$label ', style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
              color: color, blurRadius: size * .7, spreadRadius: size * .2)
        ],
      ),
    );
  }
}

@override
Widget build(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  GestureTapCallback? onTap;
  return Material(
    color: cs.surface,
    borderRadius: BorderRadius.circular(16),
    elevation: 2,
    shadowColor: Colors.black.withOpacity(.05),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.quiz_rounded,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'แบบสอบถามแนะนำต้นไม้',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'กรอกไลฟ์สไตล์สั้น ๆ แล้วให้ระบบช่วยเลือกต้นไม้ที่เหมาะกับคุณ',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    ),
  );
}

/* ======================= Recommendation Questionnaire ======================= */

class RecommendationAnswers {
  final Aspect? aspect;
  final bool hasPets;
  final int careLevel; // 0 = น้อย, 1 = ปานกลาง, 2 = เยอะ
  final bool wantAirPurify;
  final Difficulty? experience;

  const RecommendationAnswers({
    required this.aspect,
    required this.hasPets,
    required this.careLevel,
    required this.wantAirPurify,
    required this.experience,
  });
}

class PlantScore {
  final Plant plant;
  final int score;
  const PlantScore(this.plant, this.score);
}

/// ฟังก์ชันให้คะแนนความเหมาะสมของต้นไม้แต่ละต้นตามคำตอบแบบสอบถาม
int scorePlantForUser(Plant p, RecommendationAnswers a) {
  int score = 50; // เริ่มกลาง ๆ

  // 1) ทิศห้อง → แสง
  if (a.aspect != null) {
    final goodLights = lightsForAspect(a.aspect!);
    if (goodLights.contains(p.light)) {
      score += 20;
    } else {
      score -= 10;
    }
  }

  // 2) สัตว์เลี้ยง
  if (a.hasPets) {
    if (p.petSafe) {
      score += 20;
    } else {
      score -= 15;
    }
  }

  // 3) ต้องการฟอกอากาศไหม
  if (a.wantAirPurify) {
    if (p.airPurifying) {
      score += 15;
    } else {
      score -= 5;
    }
  }

  // 4) เวลาในการดูแลต่อสัปดาห์
  if (a.careLevel == 0) {
    // เวลาน้อย → ชอบต้นง่าย + รดน้ำห่าง ๆ
    if (p.difficulty == Difficulty.easy) score += 10;
    if (p.difficulty == Difficulty.hard) score -= 10;
    if (p.waterIntervalDays >= 7) score += 10;
    if (p.waterIntervalDays <= 3) score -= 10;
  } else if (a.careLevel == 2) {
    // มีเวลาเยอะ → ยอมรับต้นยาก/รดถี่ได้
    if (p.difficulty == Difficulty.hard) score += 10;
    if (p.waterIntervalDays <= 4) score += 5;
  }

  // 5) ประสบการณ์ปลูกต้นไม้
  if (a.experience != null) {
    if (a.experience == p.difficulty) {
      score += 10;
    } else if (a.experience == Difficulty.easy &&
        p.difficulty == Difficulty.hard) {
      score -= 10;
    }
  }

  // จำกัดให้อยู่ใน 0–100
  if (score < 0) score = 0;
  if (score > 100) score = 100;
  return score;
}

class RecommendationScreen extends StatefulWidget {
  final List<Plant> allPlants;
  const RecommendationScreen({super.key, required this.allPlants});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  Aspect? _aspect;
  bool _hasPets = false;
  int _careLevel = 1; // 0 น้อย, 1 กลาง, 2 เยอะ
  bool _wantAir = true;
  Difficulty? _experience = Difficulty.easy;

  List<PlantScore> _results = [];

  void _calculate() {
    final answers = RecommendationAnswers(
      aspect: _aspect,
      hasPets: _hasPets,
      careLevel: _careLevel,
      wantAirPurify: _wantAir,
      experience: _experience,
    );

    final scored = widget.allPlants
        .map((p) => PlantScore(p, scorePlantForUser(p, answers)))
        .where((ps) => ps.score > 0)
        .toList();

    scored.sort((a, b) => b.score.compareTo(a.score));

    setState(() {
      _results = scored;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('แบบสอบถามแนะนำต้นไม้'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ตอบคำถามสั้น ๆ เพื่อดูต้นไม้ที่เหมาะกับห้องและไลฟ์สไตล์ของคุณ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Q1 ทิศ
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<Aspect?>(
                  initialValue: _aspect,
                  decoration: const InputDecoration(
                    labelText: 'หน้าต่างหลักหันไปทางไหน',
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: null, child: Text('ไม่แน่ใจ / ทุกทิศ')),
                    DropdownMenuItem(
                        value: Aspect.north, child: Text('ทิศเหนือ')),
                    DropdownMenuItem(
                        value: Aspect.east, child: Text('ทิศตะวันออก')),
                    DropdownMenuItem(
                        value: Aspect.south, child: Text('ทิศใต้')),
                    DropdownMenuItem(
                        value: Aspect.west, child: Text('ทิศตะวันตก')),
                  ],
                  onChanged: (v) => setState(() => _aspect = v),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Q2 สัตว์เลี้ยง
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                title: const Text('มีสัตว์เลี้ยง (หมา/แมว) อยู่ในห้องนี้ไหม'),
                subtitle: const Text(
                    'ถ้ามี ระบบจะพยายามเลือกต้นที่ปลอดภัยต่อสัตว์เลี้ยง'),
                value: _hasPets,
                onChanged: (v) => setState(() => _hasPets = v),
              ),
            ),
            const SizedBox(height: 12),

            // Q3 เวลาในการดูแล
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<int>(
                  initialValue: _careLevel,
                  decoration: const InputDecoration(
                    labelText: 'มีเวลาให้ต้นไม้ประมาณเท่าไหร่ต่อสัปดาห์',
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 0, child: Text('น้อย (แทบไม่มีเวลาเลย)')),
                    DropdownMenuItem(
                        value: 1, child: Text('ปานกลาง (พอดูแลได้)')),
                    DropdownMenuItem(
                        value: 2, child: Text('เยอะ (ดูแลได้สม่ำเสมอ)')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _careLevel = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Q4 ฟอกอากาศ
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                title: const Text('อยากได้ต้นไม้ที่ช่วยฟอกอากาศเป็นพิเศษ'),
                value: _wantAir,
                onChanged: (v) => setState(() => _wantAir = v),
              ),
            ),
            const SizedBox(height: 12),

            // Q5 ประสบการณ์ปลูก
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<Difficulty?>(
                  initialValue: _experience,
                  decoration: const InputDecoration(
                    labelText: 'ประสบการณ์เลี้ยงต้นไม้ของคุณ',
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: Difficulty.easy,
                        child: Text('มือใหม่ / เคยปลูกนิดหน่อย')),
                    DropdownMenuItem(
                        value: Difficulty.medium,
                        child: Text('พอมีประสบการณ์')),
                    DropdownMenuItem(
                        value: Difficulty.hard,
                        child: Text('สายจริงจัง / เล่นยากได้')),
                    DropdownMenuItem(value: null, child: Text('ไม่ระบุ')),
                  ],
                  onChanged: (v) => setState(() => _experience = v),
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.recommend_rounded),
                label: const Text('ดูผลลัพธ์ที่เหมาะกับฉัน'),
              ),
            ),
            const SizedBox(height: 16),

            if (_results.isNotEmpty) ...[
              Text(
                'ผลลัพธ์ที่เหมาะกับคุณที่สุด',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._results.take(5).map(
                    (ps) => Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.primaryContainer,
                          child: Text(
                            ps.plant.nameTh.isNotEmpty
                                ? ps.plant.nameTh[0]
                                : '?',
                            style: TextStyle(color: cs.onPrimaryContainer),
                          ),
                        ),
                        title: Text(ps.plant.nameTh),
                        subtitle: Text(ps.plant.nameEn),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${ps.score}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const Text('เหมาะสม'),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

/* ============================ Shared helpers ============================ */

/// คืนค่าจำนวนวันถึงกำหนดรดน้ำครั้งถัดไป (ติดลบ = เลยกำหนด)
int daysUntilNextWater(DateTime lastWateredAt, int intervalDays) {
  final today = DateTime.now();
  final today0 = DateTime(today.year, today.month, today.day);
  final last0 =
      DateTime(lastWateredAt.year, lastWateredAt.month, lastWateredAt.day);
  final due = last0.add(Duration(days: intervalDays));
  return due.difference(today0).inDays;
}

/// แปลงจำนวนวันเป็นข้อความภาษาไทยอ่านง่าย
String describeWaterDueTH(int days) {
  if (days > 1) return 'อีก $days วัน';
  if (days == 1) return 'พรุ่งนี้';
  if (days == 0) return 'วันนี้';
  if (days == -1) return 'เลยกำหนด 1 วัน';
  return 'เลยกำหนด ${-days} วัน';
}

/// progress 0..1 จากวันที่รดครั้งก่อน ถึงวันนี้ เทียบกับช่วงรอบ
double waterProgress(DateTime lastWateredAt, int intervalDays) {
  final today = DateTime.now();
  final last0 =
      DateTime(lastWateredAt.year, lastWateredAt.month, lastWateredAt.day);
  final passed = today.difference(last0).inDays.clamp(0, intervalDays);
  return (passed / intervalDays).clamp(0, 1).toDouble();
}

/// วันที่ไทยสั้น ๆ dd/MM
String _fmtDateTH(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// ฟังก์ชันส่วนกลาง: เปิดแผ่นกรอง
void _openFilterSheet(BuildContext context, PlantFilter filter) {
  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _FilterSheet(filter: filter),
  );
}
