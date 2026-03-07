import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/plant.dart';
import '../../theme/app_colors.dart';
import '../../data/plant_repository.dart';
import '../../data/stores/favorite_store.dart';
import '../../data/stores/watering_store.dart';
import '../../data/stores/user_stats_store.dart';
import '../../data/stores/user_profile_store.dart';
import '../../data/stores/plant_filter.dart';
import '../../widgets/plant_card.dart';
import '../garden/my_garden_screen.dart';
import '../../data/stores/care_store.dart';
import '../../data/stores/app_settings_store.dart';
import '../../theme/app_strings.dart';
import '../settings/settings_screen.dart';
import '../../data/stores/activity_store.dart';
import '../../widgets/notification_bell.dart';
import '../light/light_advisor_screen.dart';
import '../detail/plant_detail_screen.dart';
import '../compare/plant_compare_screen.dart';
import '../../widgets/weather_plant_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserProfileStore profileStore = UserProfileStore();
  final all = PlantRepository.all();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    profileStore.addListener(_onAny);
  }

  @override
  void dispose() {
    profileStore.removeListener(_onAny);
    super.dispose();
  }

  void _onAny() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // Get all stores from Provider
    final fav = Provider.of<FavoriteStore>(context);
    final filter = Provider.of<PlantFilter>(context);
    final water = Provider.of<WateringStore>(context);
    final stats = Provider.of<UserStatsStore>(context);
    final care = Provider.of<CareStore>(context);
    final appSettings = Provider.of<AppSettingsStore>(context);
    final activityStore = Provider.of<ActivityStore>(context);
    final s = AppStrings.of(appSettings.language);

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          _buildExplore(context, filter, fav, water, stats, s, activityStore,
              appSettings.language),
          MyGardenScreen(
            fav: fav,
            water: water,
            stats: stats,
            profileStore: profileStore,
            careStore: care,
            settingsStore: appSettings,
            allPlants: all,
          ),
          LightAdvisorScreen(lang: appSettings.language),
          SettingsScreen(
            settingsStore: appSettings,
            profileStore: profileStore,
          ),
        ],
      ),
      bottomNavigationBar: _MinimalNavBar(
        selectedIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        labels: [s.explore, s.myGarden, s.lightAdvisor, s.settings],
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }

  Widget _buildExplore(
      BuildContext context,
      PlantFilter filter,
      FavoriteStore fav,
      WateringStore water,
      UserStatsStore stats,
      AppStrings s,
      ActivityStore activityStore,
      String lang) {
    final filtered = filter.apply(all);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 60,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
              title: Text(
                s.welcomeUser(profileStore.profile?.displayName ?? 'Plantify'),
                style: GoogleFonts.outfit(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.compare_arrows_rounded,
                    color: AppColors.primary, size: 20),
                tooltip: 'เปรียบเทียบต้นไม้',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlantCompareScreen(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: NotificationBell(
                  activityStore: activityStore,
                  lang: lang,
                ),
              ),
            ],
          ),

          // ── Search bar + quick chips ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar — minimal
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.chipBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            onChanged: filter.setQuery,
                            style: GoogleFonts.notoSansThai(
                                fontSize: 14, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: s.searchPlants,
                              hintStyle: GoogleFonts.notoSansThai(
                                  color: AppColors.textSecondary, fontSize: 14),
                              prefixIcon: const Icon(Icons.search_rounded,
                                  color: AppColors.primary, size: 18),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 11),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _openFilterSheet(context, filter, s),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: filter.hasFilters
                                ? AppColors.primary
                                : AppColors.chipBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: filter.hasFilters
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Quick Filter Chips
                  _QuickFilterChips(filter: filter, lang: lang),
                ],
              ),
            ),
          ),

          // ── Weather + Plant Recommendation ─────────────────────────────
          if (filter.query.isEmpty && !filter.hasFilters)
            SliverToBoxAdapter(
              child: WeatherPlantBanner(lang: lang),
            ),

          // ── Body: either search results or sections ──────────────
          if (filter.query.isNotEmpty || filter.hasFilters) ...[
            // Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(
                      '${s.allPlants} (${filtered.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    if (filter.hasFilters || filter.query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          filter.clear();
                          filter.setQuery('');
                        },
                        child: Text(
                          lang == 'en' ? 'Clear' : 'ล้างตัวกรอง',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (filtered.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text('ไม่พบต้นไม้ที่ค้นหา 🌿'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => PlantCard(
                      plant: filtered[i],
                      fav: fav,
                      water: water,
                      stats: stats,
                    ),
                    childCount: filtered.length,
                  ),
                ),
              ),
          ] else ...[
            // ── Plant of the Day ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _PlantOfTheDay(
                  plants: all,
                  fav: fav,
                  water: water,
                  stats: stats,
                  lang: lang,
                ),
              ),
            ),
            // ── Easy to Care ─────────────────────────────────────
            SliverToBoxAdapter(
              child: _CategorySection(
                titleTh: '🌱 ดูแลง่าย เหมาะสำหรับมือใหม่',
                titleEn: '🌱 Easy to Care — Perfect for Beginners',
                lang: lang,
                plants:
                    all.where((p) => p.difficulty == Difficulty.easy).toList(),
                fav: fav,
                water: water,
                stats: stats,
              ),
            ),
            // ── Air Purifying ─────────────────────────────────────
            SliverToBoxAdapter(
              child: _CategorySection(
                titleTh: '💨 ฟอกอากาศ ดีต่อสุขภาพ',
                titleEn: '💨 Air Purifying — Great for Health',
                lang: lang,
                plants: all.where((p) => p.airPurifying).toList(),
                fav: fav,
                water: water,
                stats: stats,
              ),
            ),
            // ── Pet Safe ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: _CategorySection(
                titleTh: '🐾 ปลอดภัยกับสัตว์เลี้ยง',
                titleEn: '🐾 Pet-Friendly Plants',
                lang: lang,
                plants: all.where((p) => p.petSafe).toList(),
                fav: fav,
                water: water,
                stats: stats,
              ),
            ),
            // ── Plant Care Guide (ปุ๋ย / ดิน / น้ำ) ─────────────────────
            SliverToBoxAdapter(
              child: _PlantCareGuide(lang: lang),
            ),
            // ── Seasonal Tips ─────────────────────────────────
            SliverToBoxAdapter(
              child: _SeasonalTipsSection(lang: lang),
            ),
            // ── All plants grid ───────────────────────────────────

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      lang == 'en'
                          ? 'All Plants (${all.length})'
                          : 'ต้นไม้ทั้งหมด (${all.length} ชนิด)',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => PlantCard(
                    plant: all[i],
                    fav: fav,
                    water: water,
                    stats: stats,
                  ),
                  childCount: all.length,
                ),
              ),
            ),
          ],

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  void _openFilterSheet(
      BuildContext context, PlantFilter filter, AppStrings s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s.filterPlants,
                              style: GoogleFonts.outfit(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () {
                              filter.clear();
                              Navigator.pop(context);
                            },
                            child: Text(s.reset,
                                style: const TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Filters...
                      _FilterSection(
                        title: 'Sunlight Direction ☀️',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: Aspect.values.map((a) {
                            final isSelected = filter.aspect == a;
                            return FilterChip(
                              label: Text(a.name.toUpperCase()),
                              selected: isSelected,
                              onSelected: (v) => filter.setAspect(v ? a : null),
                              selectedColor:
                                  AppColors.primary.withOpacity(0.15),
                              checkmarkColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey.shade300,
                                ),
                              ),
                              showCheckmark: true,
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _FilterSection(
                        title: 'Light Level 💡',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: Light.values.map((l) {
                            final isSelected = filter.light == l;
                            return FilterChip(
                              label: Text(l.name.toUpperCase()),
                              selected: isSelected,
                              onSelected: (v) => filter.setLight(v ? l : null),
                              selectedColor:
                                  AppColors.primary.withOpacity(0.15),
                              checkmarkColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withOpacity(0.5),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _FilterSection(
                        title: 'Difficulty 🌱',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: Difficulty.values.map((d) {
                            final isSelected = filter.difficulty == d;
                            return FilterChip(
                              label: Text(d.name.toUpperCase()),
                              selected: isSelected,
                              onSelected: (v) =>
                                  filter.setDifficulty(v ? d : null),
                              selectedColor:
                                  AppColors.primary.withOpacity(0.15),
                              checkmarkColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withOpacity(0.5),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Container(
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: Text(s.petSafeOnly),
                              value: filter.onlyPetSafe,
                              onChanged: (_) => filter.togglePetSafe(),
                              activeColor: AppColors.primary,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            Divider(
                                height: 1,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.2)),
                            SwitchListTile(
                              title: Text(s.airPurifyingOnly),
                              value: filter.onlyAirPurifying,
                              onChanged: (_) => filter.toggleAirPurifying(),
                              activeColor: AppColors.primary,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(s.showResults),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _FilterSection({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

// ─── Quick Filter Chips ───────────────────────────────────────────────────────

class _QuickFilterChips extends StatelessWidget {
  final PlantFilter filter;
  final String lang;
  const _QuickFilterChips({required this.filter, required this.lang});

  bool get _isTh => lang != 'en';

  @override
  Widget build(BuildContext context) {
    final chips = [
      _ChipData(
        labelTh: 'ง่าย',
        labelEn: 'Easy',
        isActive: filter.difficulty == Difficulty.easy,
        onTap: () => filter.difficulty == Difficulty.easy
            ? filter.setDifficulty(null)
            : filter.setDifficulty(Difficulty.easy),
      ),
      _ChipData(
        labelTh: 'แสงจ้า',
        labelEn: 'Bright',
        isActive: filter.light == Light.bright,
        onTap: () => filter.light == Light.bright
            ? filter.setLight(null)
            : filter.setLight(Light.bright),
      ),
      _ChipData(
        labelTh: 'แสงน้อย',
        labelEn: 'Low Light',
        isActive: filter.light == Light.low,
        onTap: () => filter.light == Light.low
            ? filter.setLight(null)
            : filter.setLight(Light.low),
      ),
      _ChipData(
        labelTh: 'ปลอดภัย',
        labelEn: 'Pet Safe',
        isActive: filter.onlyPetSafe,
        onTap: () => filter.togglePetSafe(),
      ),
      _ChipData(
        labelTh: 'ฟอกอากาศ',
        labelEn: 'Air Purify',
        isActive: filter.onlyAirPurifying,
        onTap: () => filter.toggleAirPurifying(),
      ),
    ];

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final c = chips[i];
          return GestureDetector(
            onTap: c.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: c.isActive ? AppColors.primary : AppColors.chipBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: c.isActive ? AppColors.primary : AppColors.outline,
                  width: 0.8,
                ),
              ),
              child: Text(
                _isTh ? c.labelTh : c.labelEn,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: c.isActive ? FontWeight.w600 : FontWeight.w400,
                  color: c.isActive ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChipData {
  final String labelTh;
  final String labelEn;
  final bool isActive;
  final VoidCallback onTap;
  const _ChipData({
    required this.labelTh,
    required this.labelEn,
    required this.isActive,
    required this.onTap,
  });
}

// ─── Plant of the Day ─────────────────────────────────────────────────────────

class _PlantOfTheDay extends StatelessWidget {
  final List<Plant> plants;
  final FavoriteStore fav;
  final WateringStore water;
  final UserStatsStore stats;
  final String lang;

  const _PlantOfTheDay({
    required this.plants,
    required this.fav,
    required this.water,
    required this.stats,
    required this.lang,
  });

  bool get _isTh => lang != 'en';

  @override
  Widget build(BuildContext context) {
    // Pick plant of the day based on day of year
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    final plant = plants[dayOfYear % plants.length];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlantDetailScreen(
            plant: plant,
            fav: fav,
            water: water,
            stats: stats,
          ),
        ),
      ),
      child: Container(
        height: 185,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.asset(
                plant.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.tertiary,
                ),
              ),
              // Dark gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.65),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
              // Badge + content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isTh ? '✨ ต้นไม้แห่งวัน' : '✨ Plant of the Day',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _isTh ? plant.nameTh : plant.nameEn,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      plant.scientific,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _PillBadge(
                          text: plant.difficulty == Difficulty.easy
                              ? (_isTh ? '🌱 ง่าย' : '🌱 Easy')
                              : plant.difficulty == Difficulty.medium
                                  ? (_isTh ? '⭐ ปานกลาง' : '⭐ Medium')
                                  : (_isTh ? '🔥 ยาก' : '🔥 Hard'),
                        ),
                        const SizedBox(width: 6),
                        if (plant.petSafe)
                          _PillBadge(
                              text: _isTh ? '🐾 ปลอดภัย' : '🐾 Pet Safe'),
                        if (plant.airPurifying)
                          _PillBadge(
                              text: _isTh ? '💨 ฟอกอากาศ' : '💨 Air Purify'),
                      ],
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

class _PillBadge extends StatelessWidget {
  final String text;
  const _PillBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─── Category Section (horizontal scroll) ────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final String titleTh;
  final String titleEn;
  final String lang;
  final List<Plant> plants;
  final FavoriteStore fav;
  final WateringStore water;
  final UserStatsStore stats;

  const _CategorySection({
    required this.titleTh,
    required this.titleEn,
    required this.lang,
    required this.plants,
    required this.fav,
    required this.water,
    required this.stats,
  });

  bool get _isTh => lang != 'en';

  @override
  Widget build(BuildContext context) {
    if (plants.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isTh ? titleTh : titleEn,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: plants.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(
              width: 150,
              child: PlantCard(
                plant: plants[i],
                fav: fav,
                water: water,
                stats: stats,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Plant Care Guide ─────────────────────────────────────────────────────────

class _CareGuideItem {
  final String emoji;
  final String titleTh;
  final String titleEn;
  final String subtitleTh;
  final String subtitleEn;
  final Color color;
  final List<_CareDetail> details;

  const _CareGuideItem({
    required this.emoji,
    required this.titleTh,
    required this.titleEn,
    required this.subtitleTh,
    required this.subtitleEn,
    required this.color,
    required this.details,
  });

  String title(String lang) => lang == 'en' ? titleEn : titleTh;
  String subtitle(String lang) => lang == 'en' ? subtitleEn : subtitleTh;
}

class _CareDetail {
  final String labelTh;
  final String labelEn;
  final String valueTh;
  final String valueEn;

  const _CareDetail({
    required this.labelTh,
    required this.labelEn,
    required this.valueTh,
    required this.valueEn,
  });

  String label(String lang) => lang == 'en' ? labelEn : labelTh;
  String value(String lang) => lang == 'en' ? valueEn : valueTh;
}

const _careGuideItems = [
  _CareGuideItem(
    emoji: '🌱',
    titleTh: 'ดินสำหรับไม้ใบ',
    titleEn: 'Soil for Foliage',
    subtitleTh: 'ไม้ใบทั่วไป เช่น มอนสเตอร่า, โปทอส',
    subtitleEn: 'General foliage plants like Monstera, Pothos',
    color: Color(0xFF66BB6A),
    details: [
      _CareDetail(
        labelTh: 'ส่วนผสมแนะนำ',
        labelEn: 'Recommended Mix',
        valueTh: 'ดินร่วน 60% + แกลบดำ 20% + ทราย/เพอร์ไลต์ 20%',
        valueEn: '60% potting soil + 20% perlite + 20% coco coir',
      ),
      _CareDetail(
        labelTh: 'pH ที่เหมาะสม',
        labelEn: 'Ideal pH',
        valueTh: '6.0 – 7.0 (กลาง)',
        valueEn: '6.0 – 7.0 (neutral)',
      ),
      _CareDetail(
        labelTh: 'เปลี่ยนดิน',
        labelEn: 'Repot',
        valueTh: 'ทุก 1–2 ปี หรือเมื่อรากโผล่ใต้กระถาง',
        valueEn: 'Every 1–2 years, or when roots come out of the pot',
      ),
      _CareDetail(
        labelTh: 'สัญญาณดินไม่ดี',
        labelEn: 'Bad Soil Signs',
        valueTh: 'ดินแน่น น้ำขัง ดินมีกลิ่นเน่า รากดำ',
        valueEn: 'Compacted soil, waterlogging, sour smell, black roots',
      ),
    ],
  ),
  _CareGuideItem(
    emoji: '🌵',
    titleTh: 'ดินสำหรับไม้อวบน้ำ',
    titleEn: 'Cactus & Succulent Mix',
    subtitleTh: 'แคคตัส, ซัคคิวเลนต์, ต้นหยก',
    subtitleEn: 'Cactus, Succulent, Jade Plant',
    color: Color(0xFFFFB74D),
    details: [
      _CareDetail(
        labelTh: 'ส่วนผสมแนะนำ',
        labelEn: 'Recommended Mix',
        valueTh: 'ดินแคคตัสสำเร็จ 50% + เพอร์ไลต์ 30% + ทรายหยาบ 20%',
        valueEn: '50% cactus mix + 30% perlite + 20% coarse sand',
      ),
      _CareDetail(
        labelTh: 'pH ที่เหมาะสม',
        labelEn: 'Ideal pH',
        valueTh: '6.0 – 7.5 (กลาง–ด่างเล็กน้อย)',
        valueEn: '6.0 – 7.5 (neutral to slightly alkaline)',
      ),
      _CareDetail(
        labelTh: 'เปลี่ยนดิน',
        labelEn: 'Repot',
        valueTh: 'ทุก 2–3 ปี ตอนฤดูใบไม้ผลิ',
        valueEn: 'Every 2–3 years in spring',
      ),
      _CareDetail(
        labelTh: 'ข้อสำคัญ',
        labelEn: 'Key Point',
        valueTh: 'ต้องระบายน้ำได้เร็วมาก ไม่แฉะเด็ดขาด',
        valueEn: 'Must drain fast — never allow waterlogging',
      ),
    ],
  ),
  _CareGuideItem(
    emoji: '🌸',
    titleTh: 'ดินกล้วยไม้',
    titleEn: 'Orchid Medium',
    subtitleTh: 'กล้วยไม้ฟาแลนนอปซิส, เดนโดรเบียม',
    subtitleEn: 'Phalaenopsis, Dendrobium',
    color: Color(0xFFCE93D8),
    details: [
      _CareDetail(
        labelTh: 'วัสดุปลูก',
        labelEn: 'Growing Medium',
        valueTh: 'เปลือกไม้ (Orchid bark) + สแฟกนัมมอส + เพอร์ไลต์',
        valueEn: 'Orchid bark + sphagnum moss + perlite',
      ),
      _CareDetail(
        labelTh: 'pH ที่เหมาะสม',
        labelEn: 'Ideal pH',
        valueTh: '5.5 – 6.5 (กรดเล็กน้อย)',
        valueEn: '5.5 – 6.5 (slightly acidic)',
      ),
      _CareDetail(
        labelTh: 'เปลี่ยนวัสดุ',
        labelEn: 'Repot',
        valueTh: 'ทุก 1–2 ปี หรือเมื่อเปลือกไม้เริ่มย่อยสลาย',
        valueEn: 'Every 1–2 years when bark starts to decompose',
      ),
      _CareDetail(
        labelTh: 'สำคัญ',
        labelEn: 'Important',
        valueTh: 'ห้ามใช้ดินธรรมดา รากต้องการอากาศถ่ายเท',
        valueEn: 'Never use regular soil — roots need good airflow',
      ),
    ],
  ),
  _CareGuideItem(
    emoji: '🌿',
    titleTh: 'ปุ๋ยสำหรับไม้ใบ',
    titleEn: 'Fertilizer for Foliage',
    subtitleTh: 'เร่งใบ เพิ่มความเขียวสดใส',
    subtitleEn: 'Boost leaf growth and vibrant green color',
    color: Color(0xFF26A69A),
    details: [
      _CareDetail(
        labelTh: 'สูตรที่แนะนำ',
        labelEn: 'Recommended Formula',
        valueTh: 'N-P-K = 20-20-20 หรือ 30-10-10 (ไนโตรเจนสูง)',
        valueEn: 'NPK = 20-20-20 or 30-10-10 (high nitrogen)',
      ),
      _CareDetail(
        labelTh: 'ความถี่',
        labelEn: 'Frequency',
        valueTh: 'ทุก 2–4 สัปดาห์ ในฤดูเจริญเติบโต (มี.ค.–ก.ย.)',
        valueEn: 'Every 2–4 weeks during growing season (Mar–Sep)',
      ),
      _CareDetail(
        labelTh: 'วิธีใช้',
        labelEn: 'Application',
        valueTh: 'ผสมน้ำ 1/4 ความเข้มข้น แล้วรดแทนน้ำปกติ',
        valueEn: 'Dilute to 1/4 strength and use instead of regular watering',
      ),
      _CareDetail(
        labelTh: 'สัญญาณขาดปุ๋ย',
        labelEn: 'Deficiency Signs',
        valueTh: 'ใบเหลืองซีด เจริญช้า ใบเล็กลง',
        valueEn: 'Pale yellow leaves, slow growth, smaller new leaves',
      ),
    ],
  ),
  _CareGuideItem(
    emoji: '🌺',
    titleTh: 'ปุ๋ยเร่งดอก',
    titleEn: 'Bloom Fertilizer',
    subtitleTh: 'กล้วยไม้, ลาเวนเดอร์, ไม้ดอกทั่วไป',
    subtitleEn: 'Orchids, Lavender, and flowering plants',
    color: Color(0xFFEF5350),
    details: [
      _CareDetail(
        labelTh: 'สูตรที่แนะนำ',
        labelEn: 'Recommended Formula',
        valueTh: 'N-P-K = 10-30-20 (ฟอสฟอรัสสูง)',
        valueEn: 'NPK = 10-30-20 (high phosphorus)',
      ),
      _CareDetail(
        labelTh: 'ความถี่',
        labelEn: 'Frequency',
        valueTh: 'ทุก 2 สัปดาห์ ก่อนฤดูออกดอก 2–3 เดือน',
        valueEn: 'Every 2 weeks, 2–3 months before blooming season',
      ),
      _CareDetail(
        labelTh: 'ปุ๋ยกล้วยไม้',
        labelEn: 'Orchid Special',
        valueTh: 'ใช้ปุ๋ยกล้วยไม้สูตร 30-10-10 เดือนแรก จากนั้น 10-30-20',
        valueEn: 'Start with 30-10-10, switch to 10-30-20 before blooming',
      ),
      _CareDetail(
        labelTh: 'ข้อควรระวัง',
        labelEn: 'Caution',
        valueTh: 'อย่าใส่ปุ๋ยต้นที่เพิ่งเปลี่ยนดิน ควรรอ 4–6 สัปดาห์',
        valueEn: 'Never fertilize freshly repotted plants — wait 4–6 weeks',
      ),
    ],
  ),
  _CareGuideItem(
    emoji: '🧪',
    titleTh: 'ปุ๋ยอินทรีย์ธรรมชาติ',
    titleEn: 'Organic Fertilizers',
    subtitleTh: 'ปลอดภัย ย่อยสลายได้ เป็นมิตรต่อสิ่งแวดล้อม',
    subtitleEn: 'Safe, biodegradable, eco-friendly options',
    color: Color(0xFF8D6E63),
    details: [
      _CareDetail(
        labelTh: 'ปุ๋ยหมัก (Compost)',
        labelEn: 'Compost',
        valueTh: 'ผสมลงในดิน 10–20% ช่วยปรับโครงสร้างดินดีเยี่ยม',
        valueEn: 'Mix 10–20% into soil, excellent for soil structure',
      ),
      _CareDetail(
        labelTh: 'น้ำหมักจุลินทรีย์ (EM)',
        labelEn: 'EM Fermented Water',
        valueTh: 'ผสม 1:500 กับน้ำ รดทุก 2 สัปดาห์ ช่วยให้ดินมีชีวิตชีวา',
        valueEn: 'Dilute 1:500, apply every 2 weeks for healthy soil biome',
      ),
      _CareDetail(
        labelTh: 'กากกาแฟ',
        labelEn: 'Coffee Grounds',
        valueTh: 'โรยบนดินบางๆ เพิ่มไนโตรเจน เหมาะกับไม้ชอบดินกรด',
        valueEn:
            'Sprinkle lightly on soil, adds nitrogen, good for acid-lovers',
      ),
      _CareDetail(
        labelTh: 'น้ำต้มไข่',
        labelEn: 'Egg Water',
        valueTh: 'น้ำต้มไข่เย็นแล้ว มีแคลเซียมสูง ช่วยเสริมผนังเซลล์พืช',
        valueEn: 'Cooled egg boil water — high calcium for strong plant cells',
      ),
    ],
  ),
  _CareGuideItem(
    emoji: '💧',
    titleTh: 'การรดน้ำที่ถูกต้อง',
    titleEn: 'Watering Guide',
    subtitleTh: 'เทคนิคการรดน้ำให้ถูกวิธี ป้องกันรากเน่า',
    subtitleEn: 'Proper watering technique to prevent root rot',
    color: Color(0xFF42A5F5),
    details: [
      _CareDetail(
        labelTh: 'เวลาที่ดีที่สุด',
        labelEn: 'Best Time',
        valueTh:
            'เช้าตรู่ (6:00–9:00) หรือเย็น (16:00–18:00) หลีกเลี่ยงกลางวัน',
        valueEn: 'Early morning (6–9 AM) or evening (4–6 PM), avoid midday',
      ),
      _CareDetail(
        labelTh: 'วิธีตรวจสอบ',
        labelEn: 'Check Method',
        valueTh: 'แทงนิ้วลงดิน 2–3 cm ถ้าแห้งค่อยรด ถ้าเย็นชื้นรออีก',
        valueEn: 'Stick finger 2–3 cm into soil — dry: water; cool/moist: wait',
      ),
      _CareDetail(
        labelTh: 'น้ำที่เหมาะสม',
        labelEn: 'Water Type',
        valueTh: 'น้ำประปาพักค้างคืนก่อน หรือน้ำกรอง — ลดคลอรีน',
        valueEn:
            'Let tap water sit overnight or use filtered water to reduce chlorine',
      ),
      _CareDetail(
        labelTh: 'สัญญาณรดน้ำมากเกิน',
        labelEn: 'Overwatering Signs',
        valueTh: 'ใบเหลือง, ดินมีกลิ่นเน่า, รากดำนิ่ม',
        valueEn: 'Yellow leaves, sour soil smell, dark mushy roots',
      ),
    ],
  ),
  _CareGuideItem(
    emoji: '🪲',
    titleTh: 'การจัดการศัตรูพืช',
    titleEn: 'Pest Management',
    subtitleTh: 'วิธีป้องกันและกำจัดแมลงศัตรูพืชแบบธรรมชาติ',
    subtitleEn: 'Natural ways to prevent and eliminate pests',
    color: Color(0xFFFF7043),
    details: [
      _CareDetail(
        labelTh: 'เพลี้ยแป้ง',
        labelEn: 'Mealybugs',
        valueTh: 'ใช้ cotton swab ชุบแอลกอฮอล์ 70% เช็ด หรือฉีดน้ำสบู่อ่อน',
        valueEn: 'Dab 70% alcohol on cotton swab or spray diluted dish soap',
      ),
      _CareDetail(
        labelTh: 'ไรแดง (Spider Mites)',
        labelEn: 'Spider Mites',
        valueTh: 'ฉีดน้ำแรงๆ ล้าง + สเปรย์น้ำมันสะเดา (Neem oil) 1%',
        valueEn: 'Blast with water + spray 1% neem oil solution',
      ),
      _CareDetail(
        labelTh: 'น้ำยาไล่แมลงธรรมชาติ',
        labelEn: 'Natural Repellent',
        valueTh: 'น้ำมันสะเดา 2 ml + สบู่เหลว 1 ml + น้ำ 1 ลิตร ฉีดทุก 7 วัน',
        valueEn: '2 ml neem oil + 1 ml liquid soap + 1L water, spray weekly',
      ),
      _CareDetail(
        labelTh: 'ป้องกัน',
        labelEn: 'Prevention',
        valueTh: 'เช็คใต้ใบทุกสัปดาห์ แยกต้นใหม่ก่อนนำเข้าบ้าน 2 สัปดาห์',
        valueEn: 'Check under leaves weekly, quarantine new plants for 2 weeks',
      ),
    ],
  ),
];

class _PlantCareGuide extends StatelessWidget {
  final String lang;
  const _PlantCareGuide({required this.lang});

  bool get _isTh => lang != 'en';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
          child: Row(
            children: [
              Text(
                _isTh ? '🧑‍🌾 คู่มือดูแลต้นไม้' : '🧑‍🌾 Plant Care Guide',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _isTh ? 'ปุ๋ย • ดิน • น้ำ' : 'Soil • Fertilizer • Water',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _careGuideItems.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              return _CareGuideCard(
                item: _careGuideItems[i],
                lang: lang,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CareGuideCard extends StatelessWidget {
  final _CareGuideItem item;
  final String lang;
  const _CareGuideCard({required this.item, required this.lang});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? item.color.withOpacity(0.12)
              : item.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.color.withOpacity(isDark ? 0.3 : 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji + tap hint
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 30)),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.open_in_new_rounded,
                    size: 12,
                    color: item.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title(lang),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                item.subtitle(lang),
                style: GoogleFonts.notoSansThai(
                  fontSize: 11,
                  height: 1.4,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            // Details count badge
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.details.length} ${lang == "en" ? "tips" : "รายละเอียด"}',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: item.color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2820) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                item.emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title(lang),
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: item.color,
                                  ),
                                ),
                                Text(
                                  item.subtitle(lang),
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 12,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Detail cards
                      ...item.details.map((d) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: item.color.withOpacity(0.12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.label(lang),
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: item.color,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  d.value(lang),
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 13,
                                    height: 1.6,
                                    color: isDark
                                        ? const Color(0xFFD4E8DC)
                                        : const Color(0xFF1A1A1A),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Seasonal Tips Section ────────────────────────────────────────────────────

class _SeasonalTipsSection extends StatelessWidget {
  final String lang;
  const _SeasonalTipsSection({required this.lang});

  String _getSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'summer'; // มีนา–พฤษภา (ร้อน)
    if (month >= 6 && month <= 10) return 'rainy'; // มิถุนา–ตุลา (ฝน)
    return 'cool'; // พย–กพ (เย็น)
  }

  List<_SeasonTip> _getTips(String season) {
    switch (season) {
      case 'summer':
        return [
          const _SeasonTip(
            emoji: '☀️',
            titleTh: 'รดน้ำเช้าเร็ว',
            bodyTh: 'รดน้ำก่อน 9 โมงเช้าเพื่อป้องกันน้ำระเหยเร็วและใบไหม้',
            color: Color(0xFFFFF8E1),
            accent: Color(0xFFF57F17),
          ),
          const _SeasonTip(
            emoji: '🌂',
            titleTh: 'กรองแสงแดดจ้า',
            bodyTh: 'ใช้ผ้าพรางแสง 30–50% สำหรับไม้ในร่ม ป้องกันใบไหม้',
            color: Color(0xFFFFF3E0),
            accent: Color(0xFFE65100),
          ),
          const _SeasonTip(
            emoji: '💦',
            titleTh: 'เพิ่มความชื้น',
            bodyTh: 'พ่นน้ำที่ใบตอนเช้าหรือวางถาดน้ำช่วยเพิ่ม humidity',
            color: Color(0xFFE1F5FE),
            accent: Color(0xFF0277BD),
          ),
          const _SeasonTip(
            emoji: '🌱',
            titleTh: 'เวลาขยายพันธุ์',
            bodyTh: 'หน้าร้อนเป็นช่วงที่ต้นไม้เติบโตเร็ว เหมาะกับการปักชำ',
            color: Color(0xFFE8F5E9),
            accent: Color(0xFF2E7D32),
          ),
        ];
      case 'rainy':
        return [
          const _SeasonTip(
            emoji: '🌧️',
            titleTh: 'ระวังดินเปียกเกิน',
            bodyTh: 'ตรวจดินก่อนรดน้ำทุกครั้ง ช่วงฝนดินอาจชื้นพอแล้ว',
            color: Color(0xFFE1F5FE),
            accent: Color(0xFF0277BD),
          ),
          const _SeasonTip(
            emoji: '🍄',
            titleTh: 'ป้องกันเชื้อรา',
            bodyTh: 'ตัดแต่งใบที่ชื้นและระบายอากาศดี ฉีด neem oil ป้องกัน',
            color: Color(0xFFF3E5F5),
            accent: Color(0xFF6A1B9A),
          ),
          const _SeasonTip(
            emoji: '🦠',
            titleTh: 'เฝ้าระวังศัตรูพืช',
            bodyTh: 'หน้าฝนแมลงระบาดง่าย ตรวจใต้ใบสัปดาห์ละครั้ง',
            color: Color(0xFFFFEBEE),
            accent: Color(0xFFC62828),
          ),
          const _SeasonTip(
            emoji: '🌿',
            titleTh: 'ย้ายเข้าร่ม',
            bodyTh: 'ไม้อวบน้ำและแคคตัสไม่ชอบฝน ควรย้ายมาไว้ในร่ม',
            color: Color(0xFFE8F5E9),
            accent: Color(0xFF1B4D3E),
          ),
        ];
      default: // cool
        return [
          const _SeasonTip(
            emoji: '🌡️',
            titleTh: 'ระวังอากาศเย็น',
            bodyTh: 'ต้นไม้เขตร้อนไม่ทนอุณหภูมิต่ำ ย้ายเข้าในบ้านช่วงกลางคืน',
            color: Color(0xFFE3F2FD),
            accent: Color(0xFF1565C0),
          ),
          const _SeasonTip(
            emoji: '💧',
            titleTh: 'ลดการรดน้ำ',
            bodyTh: 'หน้าหนาวต้นไม้โตช้า ลดความถี่การรดน้ำลง 30–50%',
            color: Color(0xFFE1F5FE),
            accent: Color(0xFF0277BD),
          ),
          const _SeasonTip(
            emoji: '🌞',
            titleTh: 'เพิ่มแสงแดด',
            bodyTh: 'วันสั้นลง ย้ายต้นไม้ไปที่ที่รับแสงได้มากขึ้น',
            color: Color(0xFFFFF8E1),
            accent: Color(0xFFF57F17),
          ),
          const _SeasonTip(
            emoji: '🛑',
            titleTh: 'หยุดใส่ปุ๋ย',
            bodyTh: 'ช่วงพักตัวของพืช ไม่ควรใส่ปุ๋ย รอถึงฤดูใบไม้ผลิ',
            color: Color(0xFFFBE9E7),
            accent: Color(0xFFBF360C),
          ),
        ];
    }
  }

  String _seasonLabel(String season) {
    switch (season) {
      case 'summer':
        return '☀️ ทิปหน้าร้อน';
      case 'rainy':
        return '🌧️ ทิปหน้าฝน';
      default:
        return '🌥️ ทิปหน้าเย็น';
    }
  }

  @override
  Widget build(BuildContext context) {
    final season = _getSeason();
    final tips = _getTips(season);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Text(
                  _seasonLabel(season),
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ตามฤดูกาล',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: tips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _SeasonTipCard(tip: tips[i]),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SeasonTip {
  final String emoji;
  final String titleTh;
  final String bodyTh;
  final Color color;
  final Color accent;

  const _SeasonTip({
    required this.emoji,
    required this.titleTh,
    required this.bodyTh,
    required this.color,
    required this.accent,
  });
}

class _SeasonTipCard extends StatelessWidget {
  final _SeasonTip tip;
  const _SeasonTipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // In dark mode blend accent colour heavily so card is readable on dark bg
    final cardColor = isDark ? tip.accent.withOpacity(0.15) : tip.color;
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tip.accent.withOpacity(isDark ? 0.35 : 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tip.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tip.titleTh,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: tip.accent,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              tip.bodyTh,
              style: GoogleFonts.notoSansThai(
                fontSize: 11.5,
                height: 1.5,
                color: tip.accent.withOpacity(0.75),
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Minimal Bottom Nav Bar ───────────────────────────────────────────────────

class _MinimalNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<String> labels;
  final bool isDark;

  const _MinimalNavBar({
    required this.selectedIndex,
    required this.onTap,
    required this.labels,
    required this.isDark,
  });

  static const List<List<IconData>> _icons = [
    [Icons.explore_outlined, Icons.explore_rounded],
    [Icons.yard_outlined, Icons.yard_rounded],
    [Icons.wb_sunny_outlined, Icons.wb_sunny_rounded],
    [Icons.settings_outlined, Icons.settings_rounded],
  ];

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF0F1A14) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1E3028) : const Color(0xFFEEEEEE);
    final activeColor = AppColors.primary;
    final inactiveColor =
        isDark ? const Color(0xFF3A5040) : const Color(0xFFBBBBBB);

    return Container(
      height: 58 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          children: List.generate(labels.length, (i) {
            final isSelected = i == selectedIndex;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? _icons[i][1] : _icons[i][0],
                        size: 22,
                        color: isSelected ? activeColor : inactiveColor,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        labels[i],
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? activeColor : inactiveColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
