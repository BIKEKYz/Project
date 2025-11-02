// lib/main.dart — Plantify 🪴 + Firebase Auth (Google Sign-In)
// วางไฟล์นี้ทับของเดิมได้เลย

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

/* ============================== App Bootstrap ============================== */

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CondoPlantApp());
}

class CondoPlantApp extends StatelessWidget {
  const CondoPlantApp({super.key});
  static const seed = Color(0xFF2C4A33);

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.notoSansThaiTextTheme(
      ThemeData.light().textTheme,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plantify🪴',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF6F7F4),
        textTheme: textTheme,
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
        final provider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final gUser = await GoogleSignIn().signIn();
        if (gUser == null) return;
        final gAuth = await gUser.authentication;
        final cred = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken,
          idToken: gAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(cred);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
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
      return _SignInScreen(onGoogle: _signIn);
    }
    return const SplashScreen();
  }
}

/* ========================== Beautiful Sign-in UI ========================== */

class _SignInScreen extends StatelessWidget {
  final VoidCallback onGoogle;
  const _SignInScreen({required this.onGoogle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ระยะห่างที่บาลานซ์กับหน้าจอ (responsive)
    final size = MediaQuery.of(context).size;
    final horizontalPad = size.width <= 420 ? 16.0 : 20.0;
    final verticalPad = size.height <= 720 ? 8.0 : 12.0;
    final align = size.width >= 900
        ? const Alignment(-0.55, 0.0) // ชิดซ้ายราว 55% บนจอใหญ่
        : Alignment.center; // จอเล็กจัดกลาง

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AnimatedBackdrop(),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: horizontalPad, vertical: verticalPad),
              child: Align(
                alignment: align,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _Glass(
                    elevation: 18,
                    radius: 28,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                      child: _StaggeredEnter(
                        delays: const [0, 90, 160, 260],
                        children: [
                          // โลโก้ในวงแหวนแสง
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const _PulseHalo(size: 86),
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: cs.primary.withOpacity(.18),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      )
                                    ],
                                  ),
                                  child: Icon(Icons.eco_rounded,
                                      size: 40, color: cs.onPrimaryContainer),
                                ),
                              ],
                            ),
                          ),

                          // ข้อความต้อนรับ
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 18),
                              Text(
                                'ยินดีต้อนรับสู่ Plantify 🪴',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'เข้าสู่ระบบด้วย Google เพื่อบันทึกรายการโปรด ซิงก์ข้อมูล และเริ่มต้นประสบการณ์สวนในคอนโดแบบมืออาชีพ',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),

                          // ปุ่ม Google
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: GoogleButton(onPressed: onGoogle),
                            ),
                          ),

                          // ข้อความกำกับ
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'โดยดำเนินการต่อ คุณยอมรับนโยบายความเป็นส่วนตัวและเงื่อนไขการใช้งาน',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// พื้นหลังกราเดียนต์ที่ค่อย ๆ เคลื่อนที่ ให้ความรู้สึก premium
class _AnimatedBackdrop extends StatefulWidget {
  const _AnimatedBackdrop();
  @override
  State<_AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<_AnimatedBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _ac,
      builder: (_, __) {
        final t = _ac.value;
        final c1 = Color.lerp(const Color(0xFFEFF6F1), cs.surface, 0.10)!;
        final c2 = Color.lerp(
            cs.primary.withOpacity(.22), const Color(0xFFB8E2C2), t)!;
        final c3 = Color.lerp(
            const Color(0xFFF9FBF7), const Color(0xFFE7F2EA), 1 - t)!;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + t, -1),
              end: Alignment(1, 1 - t),
              colors: [c1, c2, c3],
            ),
          ),
        );
      },
    );
  }
}

/// การ์ดใสแบบ glass (blur + translucent)
class _Glass extends StatelessWidget {
  final Widget child;
  final double radius;
  final double elevation;
  const _Glass({required this.child, this.radius = 24, this.elevation = 12});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(.60),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.07),
                blurRadius: elevation,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// เข้าเฟรมแบบเว้นจังหวะ (stagger) + เฟด + เลื่อนขึ้นเล็กน้อย
class _StaggeredEnter extends StatelessWidget {
  final List<Widget> children;
  final List<int> delays; // ms เทียบตำแหน่ง children
  const _StaggeredEnter({required this.children, required this.delays});

  @override
  Widget build(BuildContext context) {
    assert(
        children.length == delays.length, 'children & delays ต้องยาวเท่ากัน');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++)
          _EnterItem(delayMs: delays[i], child: children[i]),
      ],
    );
  }
}

class _EnterItem extends StatefulWidget {
  final int delayMs;
  final Widget child;
  const _EnterItem({required this.delayMs, required this.child});
  @override
  State<_EnterItem> createState() => _EnterItemState();
}

class _EnterItemState extends State<_EnterItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, .06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ac.forward();
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// วงแหวนแสงเต้นเบา ๆ รอบโลโก้
class _PulseHalo extends StatefulWidget {
  final double size;
  const _PulseHalo({this.size = 80});
  @override
  State<_PulseHalo> createState() => _PulseHaloState();
}

class _PulseHaloState extends State<_PulseHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _ac,
      builder: (_, __) {
        final t = (_ac.value - .2).clamp(0.0, 1.0);
        final opacity = (1 - t) * .35;
        final size = widget.size + t * 26;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primary.withOpacity(opacity),
          ),
        );
      },
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
      duration: const Duration(milliseconds: 900),
    );
    _scale = CurvedAnimation(parent: _ac, curve: Curves.easeOutBack);
    _ac.forward();
    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
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
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(28),
            ),
            child:
                Icon(Icons.eco_rounded, size: 64, color: cs.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}

/* ================================ Domain ================================= */

enum Light { low, medium, bright }

enum SizeClass { tiny, small, medium }

enum Difficulty { easy, medium, hard }

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
    required String description,
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
      ];

  // เพิ่มฟิลด์คำอธิบายให้ตัวอย่าง
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
  Set<String> get all => _ids;

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

/* ============================ Filters / State ============================ */

class PlantFilter with ChangeNotifier {
  String query = '';
  Light? light;
  bool onlyPetSafe = false;
  bool onlyAirPurifying = false;
  Difficulty? difficulty;

  void clear() {
    query = '';
    light = null;
    difficulty = null;
    onlyPetSafe = false;
    onlyAirPurifying = false;
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
      return okQ && okLight && okDiff && okPet && okAir;
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
  late final FavoriteStore fav;
  late final PlantFilter filter;
  final all = PlantRepository.all();
  User? user;

  @override
  void initState() {
    super.initState();
    fav = FavoriteStore();
    filter = PlantFilter();
    fav.addListener(_onAny);
    filter.addListener(_onAny);
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
    super.dispose();
  }

  void _onAny() => setState(() {});

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
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
    final showEmpty = fav.isReady && filtered.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Plantify 🪴',
          style: GoogleFonts.notoSansThai(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'บัญชีของฉัน',
            onPressed: () => _openAccountSheet(context, user),
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: cs.primaryContainer,
              backgroundImage:
                  user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
          ),
          IconButton(
            tooltip: 'รายการโปรด',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FavoriteScreen(fav: fav, plants: all),
              ));
            },
            icon: Stack(
              children: [
                const Icon(Icons.favorite_outline_rounded),
                if (fav.count > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          '${fav.count}',
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'ล้างตัวกรอง',
            onPressed: filter.clear,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            _SearchBar(filter: filter),
            const SizedBox(height: 12),
            _QuickFilters(filter: filter),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: showEmpty
                    ? _EmptyState(onClear: filter.clear)
                    : _PlantGrid(plants: filtered, fav: fav),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _signOut,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Sign out'),
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
            ListTile(
              leading: const Icon(Icons.cloud_done_rounded),
              title: const Text('ซิงก์รายการโปรด & การตั้งค่า'),
              subtitle: const Text('พร้อมใช้งานเมื่อเชื่อมต่อบัญชี'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                label: const Text('ปิด'),
              ),
            )
          ],
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
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _openFilterSheet(context, filter),
            icon: const Icon(Icons.tune_rounded),
            label: const Text('กรอง'),
          ),
        ),
      ],
    );
  }

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
              const SizedBox(width: 6),
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
          _LightPill(filter: filter),
          const SizedBox(width: 8),
          _DiffPill(filter: filter),
        ],
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
  const _PlantGrid({required this.plants, required this.fav});

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
      itemBuilder: (context, i) => _PlantCard(plant: plants[i], fav: fav),
    );
  }
}

class _PlantCard extends StatelessWidget {
  final Plant plant;
  final FavoriteStore fav;
  const _PlantCard({required this.plant, required this.fav});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PlantDetailScreen(plant: plant, fav: fav),
        ));
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  plant.image,
                  height: 84,
                  width: 84,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                plant.nameTh,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                plant.nameEn,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
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
                  if (plant.petSafe)
                    const _Pill(icon: Icons.pets_rounded, text: 'Pet-safe'),
                  if (plant.airPurifying)
                    const _Pill(icon: Icons.air_rounded, text: 'ฟอกอากาศ'),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton.filledTonal(
                  tooltip: fav.isFavorite(plant.id)
                      ? 'นำออกจากโปรด'
                      : 'เพิ่มรายการโปรด',
                  onPressed: () => fav.toggle(plant.id),
                  icon: Icon(
                    fav.isFavorite(plant.id)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                  ),
                ),
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: cs.onPrimaryContainer,
                fontSize: 36,
              ),
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
          Text('ลองเปลี่ยนตัวกรองหรือเคลียร์ทั้งหมด',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.outline)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onClear, child: const Text('ล้างตัวกรอง'))
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

    Widget section(String title, Widget child) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: cs.onSurface)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
    }

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
  const PlantDetailScreen({super.key, required this.plant, required this.fav});

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
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(value, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ),
      );
    }

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
                  tag: 'avatar_${plant.id}',
                  child: _AvatarLetter(id: plant.id)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plant.nameEn,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(plant.scientific,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant)),
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
                        if (plant.petSafe)
                          const _Pill(
                              icon: Icons.pets_rounded, text: 'Pet-safe'),
                        if (plant.airPurifying)
                          const _Pill(
                              icon: Icons.air_rounded, text: 'ฟอกอากาศ'),
                      ],
                    )
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

/* =============================== Favorites =============================== */

class FavoriteScreen extends StatelessWidget {
  final FavoriteStore fav;
  final List<Plant> plants;
  const FavoriteScreen({super.key, required this.fav, required this.plants});

  @override
  Widget build(BuildContext context) {
    final list = plants.where((p) => fav.isFavorite(p.id)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('รายการโปรด')),
      body: list.isEmpty
          ? const Center(child: Text('ยังไม่มีรายการโปรด'))
          : _PlantGrid(plants: list, fav: fav),
    );
  }
}

/* ============================= Google Button ============================= */

class GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  const GoogleButton({
    super.key,
    required this.onPressed,
    this.label = 'Sign in with Google',
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
                _GoogleGlyph(),
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

class _GoogleGlyph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/google_g.png',
      width: 18,
      height: 18,
      errorBuilder: (c, e, s) => Container(
        width: 18,
        height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFDADCE0)),
        ),
        child: const Text(
          'G',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }
}
