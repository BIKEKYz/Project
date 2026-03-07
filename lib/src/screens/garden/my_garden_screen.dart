import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/plant.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_strings.dart';
import '../../data/stores/favorite_store.dart';
import '../../data/stores/watering_store.dart';
import '../../data/stores/user_stats_store.dart';
import '../../data/stores/user_profile_store.dart';
import '../../data/stores/care_store.dart';
import '../../data/stores/app_settings_store.dart';
import '../detail/plant_detail_screen.dart';
import 'care_schedule_screen.dart';
import 'care_calendar_screen.dart';
import '../quiz/plant_quiz_screen.dart';

// ─── Plant Tips Data ──────────────────────────────────────────────────────────

class _PlantTip {
  final String emoji;
  final String titleTh;
  final String titleEn;
  final String bodyTh;
  final String bodyEn;
  final Color color;

  const _PlantTip({
    required this.emoji,
    required this.titleTh,
    required this.titleEn,
    required this.bodyTh,
    required this.bodyEn,
    required this.color,
  });

  String title(String lang) => lang == 'en' ? titleEn : titleTh;
  String body(String lang) => lang == 'en' ? bodyEn : bodyTh;
}

const _tips = [
  _PlantTip(
    emoji: '💧',
    titleTh: 'รดน้ำให้ถูกเวลา',
    titleEn: 'Water at the Right Time',
    bodyTh: 'รดน้ำตอนเช้าตรู่หรือเย็น ช่วยให้รากดูดซึมน้ำได้ดีขึ้น',
    bodyEn: 'Water in the early morning or evening for better root absorption.',
    color: Color(0xFF4FC3F7),
  ),
  _PlantTip(
    emoji: '☀️',
    titleTh: 'แสงแดดสำคัญมาก',
    titleEn: 'Sunlight Matters',
    bodyTh: 'ต้นไม้ส่วนใหญ่ต้องการแสงอย่างน้อย 6 ชั่วโมงต่อวัน',
    bodyEn: 'Most plants need at least 6 hours of sunlight per day.',
    color: Color(0xFFFFB74D),
  ),
  _PlantTip(
    emoji: '🌱',
    titleTh: 'ดินที่ดี = ต้นไม้แข็งแรง',
    titleEn: 'Good Soil = Strong Plants',
    bodyTh: 'ใช้ดินที่ระบายน้ำดี ผสมเพอร์ไลต์เพื่อป้องกันรากเน่า',
    bodyEn: 'Use well-draining soil mixed with perlite to prevent root rot.',
    color: Color(0xFF81C784),
  ),
  _PlantTip(
    emoji: '🌡️',
    titleTh: 'อุณหภูมิที่เหมาะสม',
    titleEn: 'Ideal Temperature',
    bodyTh: 'ต้นไม้ในร่มชอบอุณหภูมิ 18–27°C หลีกเลี่ยงแอร์เย็นจัด',
    bodyEn: 'Indoor plants prefer 18–27°C. Avoid cold AC drafts.',
    color: Color(0xFFBA68C8),
  ),
  _PlantTip(
    emoji: '🍃',
    titleTh: 'เช็ดใบให้สะอาด',
    titleEn: 'Clean the Leaves',
    bodyTh: 'เช็ดฝุ่นออกจากใบเดือนละครั้ง ช่วยให้สังเคราะห์แสงได้ดีขึ้น',
    bodyEn: 'Wipe dust off leaves monthly to improve photosynthesis.',
    color: Color(0xFF4DB6AC),
  ),
  _PlantTip(
    emoji: '🪲',
    titleTh: 'ป้องกันแมลงศัตรูพืช',
    titleEn: 'Pest Prevention',
    bodyTh: 'ตรวจใต้ใบสัปดาห์ละครั้ง หากพบแมลงให้ใช้น้ำสบู่อ่อนๆ ฉีด',
    bodyEn: 'Check under leaves weekly. Use mild soapy water for pests.',
    color: Color(0xFFFF8A65),
  ),
];

// ─── Main Screen ──────────────────────────────────────────────────────────────

class MyGardenScreen extends StatelessWidget {
  final FavoriteStore fav;
  final WateringStore water;
  final UserStatsStore stats;
  final UserProfileStore? profileStore;
  final CareStore? careStore;
  final AppSettingsStore? settingsStore;
  final List<Plant> allPlants;

  const MyGardenScreen({
    super.key,
    required this.fav,
    required this.water,
    required this.stats,
    this.profileStore,
    this.careStore,
    this.settingsStore,
    required this.allPlants,
  });

  @override
  Widget build(BuildContext context) {
    final myPlants = allPlants.where((p) => fav.isFavorite(p.id)).toList();
    final lang = settingsStore?.language ?? 'th';
    final s = AppStrings.of(lang);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTh = lang != 'en';

    // Plants needing water today/overdue
    final needsWater = myPlants
        .where(
            (p) => water.nextWatering(p).difference(DateTime.now()).inDays <= 0)
        .toList();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D1A12) : const Color(0xFFF5F7F2),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor:
                isDark ? const Color(0xFF0D1A12) : const Color(0xFFF5F7F2),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
              title: Text(
                s.myGardenTitle,
                style: GoogleFonts.outfit(
                  color: isDark ? const Color(0xFF7DC99A) : AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
            actions: [
              // Quiz button
              _AppBarAction(
                icon: Icons.quiz_outlined,
                tooltip: isTh ? 'ทดสอบความรู้' : 'Plant Quiz',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlantQuizScreen(lang: lang),
                  ),
                ),
              ),
              if (careStore != null)
                _AppBarAction(
                  icon: Icons.calendar_month_outlined,
                  tooltip: s.careSchedule,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CareScheduleScreen(
                        careStore: careStore!,
                        allPlants: allPlants,
                      ),
                    ),
                  ),
                ),
              if (careStore != null)
                _AppBarAction(
                  icon: Icons.calendar_today_outlined,
                  tooltip: s.careCalendar,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CareCalendarScreen(
                        careStore: careStore!,
                        allPlants: allPlants,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 4),
            ],
          ),

          // ── Stats Dashboard ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _StatsDashboard(
                myPlants: myPlants,
                water: water,
                stats: stats,
                lang: lang,
                isDark: isDark,
              ),
            ),
          ),

          // ── Today's Tasks ─────────────────────────────────────
          if (needsWater.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _TodaysTasks(
                  plants: needsWater,
                  water: water,
                  fav: fav,
                  stats: stats,
                  careStore: careStore,
                  lang: lang,
                  isDark: isDark,
                  isTh: isTh,
                ),
              ),
            ),

          // ── Quiz Banner ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _QuizBanner(lang: lang, isDark: isDark, isTh: isTh),
            ),
          ),

          // ── Plant Tips ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
              child: _PlantTipsSection(lang: lang, isDark: isDark),
            ),
          ),

          // ── Section header for plants ─────────────────────────
          if (myPlants.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Row(
                  children: [
                    Text(
                      isTh ? 'ต้นไม้ของฉัน 🌿' : 'My Plants 🌿',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFD4E8DC)
                            : const Color(0xFF1A1A1A),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${myPlants.length} ${isTh ? "ต้น" : "plants"}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Plants Grid ────────────────────────────────────────
          if (myPlants.isEmpty)
            SliverFillRemaining(child: _EmptyState(s: s, lang: lang))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final plant = myPlants[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlantDetailScreen(
                            plant: plant,
                            fav: fav,
                            water: water,
                            stats: stats,
                            careStore: careStore,
                          ),
                        ),
                      ),
                      child: _MyPlantCard(
                          plant: plant, water: water, s: s, isDark: isDark),
                    );
                  },
                  childCount: myPlants.length,
                ),
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}

// ─── Stats Dashboard ──────────────────────────────────────────────────────────

class _StatsDashboard extends StatelessWidget {
  final List<Plant> myPlants;
  final WateringStore water;
  final UserStatsStore stats;
  final String lang;
  final bool isDark;

  const _StatsDashboard({
    required this.myPlants,
    required this.water,
    required this.stats,
    required this.lang,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isTh = lang != 'en';
    final totalWatered = myPlants
        .where(
            (p) => water.nextWatering(p).difference(DateTime.now()).inDays > 0)
        .length;
    final needsWaterCount = myPlants.length - totalWatered;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2820) : AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2A4035) : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTh ? 'สถิติสวนของฉัน' : 'My Garden Stats',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFD4E8DC) : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  emoji: '🌿',
                  value: '${myPlants.length}',
                  label: isTh ? 'ต้นไม้' : 'Plants',
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _StatItem(
                  emoji: '💧',
                  value: '$needsWaterCount',
                  label: isTh ? 'รดน้ำ' : 'Need Water',
                  color: needsWaterCount > 0
                      ? const Color(0xFF2196F3)
                      : const Color(0xFF4CAF50),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _StatItem(
                  emoji: '🔥',
                  value: '${water.currentStreak}',
                  label: isTh ? 'วันติดกัน' : 'Streak',
                  color: const Color(0xFFFF6D00),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _StatItem(
                  emoji: '🏆',
                  value: '${stats.xp}',
                  label: 'XP',
                  color: const Color(0xFFFFB300),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          if (myPlants.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              isTh
                  ? 'การดูแลสัปดาห์นี้: $totalWatered / ${myPlants.length} ต้น'
                  : 'Care this week: $totalWatered / ${myPlants.length} plants',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color:
                    isDark ? const Color(0xFF5A7A65) : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: myPlants.isEmpty ? 0 : totalWatered / myPlants.length,
                minHeight: 5,
                backgroundColor: AppColors.primary.withOpacity(0.06),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _StatItem({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.10 : 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: isDark ? const Color(0xFF5A7A65) : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Today's Tasks ────────────────────────────────────────────────────────────

class _TodaysTasks extends StatelessWidget {
  final List<Plant> plants;
  final WateringStore water;
  final FavoriteStore fav;
  final UserStatsStore stats;
  final CareStore? careStore;
  final String lang;
  final bool isDark;
  final bool isTh;

  const _TodaysTasks({
    required this.plants,
    required this.water,
    required this.fav,
    required this.stats,
    this.careStore,
    required this.lang,
    required this.isDark,
    required this.isTh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2820) : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF2196F3).withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💧', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                isTh
                    ? 'ต้องรดน้ำวันนี้ (${plants.length} ต้น)'
                    : 'Need Water Today (${plants.length})',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...plants.take(3).map((plant) => _TaskRow(
                plant: plant,
                water: water,
                stats: stats,
                lang: lang,
                isDark: isDark,
                isTh: isTh,
              )),
          if (plants.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                isTh
                    ? '+${plants.length - 3} ต้นอื่นๆ...'
                    : '+${plants.length - 3} more...',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF2196F3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final Plant plant;
  final WateringStore water;
  final UserStatsStore stats;
  final String lang;
  final bool isDark;
  final bool isTh;

  const _TaskRow({
    required this.plant,
    required this.water,
    required this.stats,
    required this.lang,
    required this.isDark,
    required this.isTh,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft =
        water.nextWatering(plant).difference(DateTime.now()).inDays;
    final overdue = daysLeft < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2820) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              plant.image,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 36,
                height: 36,
                color: AppColors.tertiary,
                child: const Center(
                  child: Text('🌿', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == 'en' ? plant.nameEn : plant.nameTh,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFD4E8DC)
                        : const Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  overdue
                      ? (isTh
                          ? 'เลยกำหนด ${-daysLeft} วัน!'
                          : '${-daysLeft} days overdue!')
                      : (isTh ? 'ถึงเวลารดน้ำแล้ว' : 'Time to water'),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: overdue ? AppColors.error : const Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              water.setNow(plant.id);
              stats.addXp(10);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isTh
                        ? '💧 รดน้ำ${lang == "en" ? plant.nameEn : plant.nameTh}แล้ว +10 XP'
                        : '💧 Watered ${plant.nameEn}! +10 XP',
                    style: GoogleFonts.notoSansThai(fontSize: 13),
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isTh ? 'รดน้ำ' : 'Water',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quiz Banner ──────────────────────────────────────────────────────────────

class _QuizBanner extends StatelessWidget {
  final String lang;
  final bool isDark;
  final bool isTh;

  const _QuizBanner(
      {required this.lang, required this.isDark, required this.isTh});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlantQuizScreen(lang: lang)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2820) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? const Color(0xFF2A4035)
                : AppColors.primary.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            const Text('🧠', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTh ? 'ทดสอบความรู้ต้นไม้' : 'Plant Knowledge Quiz',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? const Color(0xFF7DC99A) : AppColors.primary,
                    ),
                  ),
                  Text(
                    isTh
                        ? '10 ข้อ • ดูรูปแล้วทาย • มีคำอธิบาย'
                        : '10 questions • Identify plants • Learn facts',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF5A7A65)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isTh ? 'เริ่ม' : 'Start',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App Bar Action ───────────────────────────────────────────────────────────

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _AppBarAction(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon,
            size: 22,
            color: isDark ? const Color(0xFF7DC99A) : AppColors.primary),
        tooltip: tooltip,
      ),
    );
  }
}

// ─── Plant Tips Section ───────────────────────────────────────────────────────

class _PlantTipsSection extends StatelessWidget {
  final String lang;
  final bool isDark;
  const _PlantTipsSection({required this.lang, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 12),
          child: Text(
            lang == 'en' ? 'Plant Tips 🌿' : 'เคล็ดลับต้นไม้ 🌿',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFD4E8DC) : const Color(0xFF1A1A1A),
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 16),
            itemCount: _tips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final tip = _tips[i];
              return _TipCard(tip: tip, lang: lang, isDark: isDark);
            },
          ),
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  final _PlantTip tip;
  final String lang;
  final bool isDark;
  const _TipCard({required this.tip, required this.lang, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark ? tip.color.withOpacity(0.12) : tip.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: tip.color.withOpacity(isDark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tip.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            tip.title(lang),
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFD4E8DC) : const Color(0xFF1A1A1A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              tip.body(lang),
              style: GoogleFonts.notoSansThai(
                fontSize: 11,
                height: 1.5,
                color:
                    isDark ? const Color(0xFF7A9A85) : const Color(0xFF757575),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── My Plant Card (Enhanced) ─────────────────────────────────────────────────

class _MyPlantCard extends StatelessWidget {
  final Plant plant;
  final WateringStore water;
  final AppStrings s;
  final bool isDark;

  const _MyPlantCard(
      {required this.plant,
      required this.water,
      required this.s,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final nextWater = water.nextWatering(plant);
    final daysLeft = nextWater.difference(DateTime.now()).inDays;
    final needsWater = daysLeft <= 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3028) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    plant.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.tertiary),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  if (needsWater)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.water_drop_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  // Difficulty badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        plant.difficulty == Difficulty.easy
                            ? '⭐'
                            : plant.difficulty == Difficulty.medium
                                ? '⭐⭐'
                                : '⭐⭐⭐',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.nameEn,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFFD4E8DC)
                        : const Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  plant.nameTh,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF5A7A65) : Colors.black45,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Water status
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: needsWater
                        ? const Color(0xFF2196F3).withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.water_drop_rounded,
                        size: 10,
                        color: needsWater
                            ? const Color(0xFF2196F3)
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          needsWater ? s.waterNow : s.inDays(daysLeft),
                          style: GoogleFonts.notoSansThai(
                            fontSize: 10,
                            color: needsWater
                                ? const Color(0xFF2196F3)
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppStrings s;
  final String lang;
  const _EmptyState({required this.s, required this.lang});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTh = lang != 'en';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E3028)
                  : AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              Icons.yard_outlined,
              size: 44,
              color: AppColors.primary.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            s.gardenEmpty,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF5A7A65) : AppColors.outline,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.gardenEmptySub,
            style: GoogleFonts.notoSansThai(
              fontSize: 13,
              color: isDark
                  ? const Color(0xFF3A5040)
                  : AppColors.outline.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isTh
                ? '💡 กดหัวใจ ❤️ ที่ต้นไม้ที่ชอบเพื่อเพิ่มในสวน'
                : '💡 Tap ❤️ on a plant to add it here',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansThai(
              fontSize: 13,
              color: AppColors.primary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
