import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'src/theme/app_colors.dart';
import 'src/screens/splash_screen.dart';
import 'src/data/stores/favorite_store.dart';
import 'src/data/stores/watering_store.dart';
import 'src/data/stores/user_stats_store.dart';
import 'src/data/stores/care_store.dart';
import 'src/data/stores/plant_filter.dart';
import 'src/data/stores/app_settings_store.dart';
import 'src/data/stores/activity_store.dart';
import 'src/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for Google Sign-In
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('⚠️ Firebase init failed (offline mode OK): $e');
  }

  try {
    final dbInit = DatabaseInitializer();
    await dbInit.initialize();
    debugPrint('✅ Database initialized successfully');
  } catch (e) {
    debugPrint('❌ Error initializing database: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const PlantifyApp());
}

class PlantifyApp extends StatelessWidget {
  const PlantifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettingsStore()),
        ChangeNotifierProvider(create: (_) => ActivityStore()),
        ChangeNotifierProvider(create: (_) => FavoriteStore()),
        ChangeNotifierProvider(create: (_) => WateringStore()),
        ChangeNotifierProvider(create: (_) => UserStatsStore()),
        ChangeNotifierProvider(create: (_) => CareStore()),
        ChangeNotifierProvider(create: (_) => PlantFilter()),
      ],
      child: Consumer<AppSettingsStore>(
        builder: (context, settings, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Plantify 🪴',
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.notoSansThaiTextTheme(ThemeData.light().textTheme),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const darkBg = Color(0xFF0F1A14);
    const darkSurface = Color(0xFF1A2820);
    const darkCard = Color(0xFF1E3028);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        surface: darkSurface,
      ),
      scaffoldBackgroundColor: darkBg,
      textTheme: GoogleFonts.notoSansThaiTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: darkCard,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.outfit(
          color: const Color(0xFF7DC99A),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF7DC99A)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
