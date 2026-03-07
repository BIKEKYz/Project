import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/stores/weather_store.dart';
import '../data/plant_repository.dart';
import '../models/plant.dart';
import '../screens/detail/plant_detail_screen.dart';
import '../data/stores/favorite_store.dart';
import '../data/stores/watering_store.dart';
import '../data/stores/user_stats_store.dart';
import '../services/weather/weather_service.dart';
import '../theme/app_colors.dart';

/// Minimal weather-based plant recommendation banner
/// Sits at the top of the home explore tab content
class WeatherPlantBanner extends StatefulWidget {
  final String lang;
  const WeatherPlantBanner({super.key, required this.lang});

  @override
  State<WeatherPlantBanner> createState() => _WeatherPlantBannerState();
}

class _WeatherPlantBannerState extends State<WeatherPlantBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  bool get _isTh => widget.lang != 'en';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = context.read<WeatherStore>();
      if (store.state == WeatherLoadState.idle) {
        store.fetchWeather();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherStore>(builder: (ctx, store, _) {
      if (store.state == WeatherLoadState.loaded) _ctrl.forward();
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: _body(ctx, store, isDark),
      );
    });
  }

  Widget _body(BuildContext ctx, WeatherStore store, bool isDark) {
    if (store.isLoading) return _Skeleton(isDark: isDark);

    if (!store.hasData) {
      return _RetryChip(isTh: _isTh, onTap: store.refresh);
    }

    final weather = store.weather!;
    final tips = store.tips;
    if (tips.isEmpty) return const SizedBox.shrink();

    final tip = tips.first;
    final accent = Color(tip.accentColorValue);

    return FadeTransition(
      opacity: _fade,
      child: _WeatherCard(
        weather: weather,
        tip: tip,
        accent: accent,
        isTh: _isTh,
        lang: widget.lang,
        isDark: isDark,
        onRefresh: store.refresh,
      ),
    );
  }
}

// ─── Skeleton loader ──────────────────────────────────────────────────────────
class _Skeleton extends StatelessWidget {
  final bool isDark;
  const _Skeleton({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3028) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}

// ─── Retry chip ───────────────────────────────────────────────────────────────
class _RetryChip extends StatelessWidget {
  final bool isTh;
  final VoidCallback onTap;
  const _RetryChip({required this.isTh, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E3028) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Text('🌡️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isTh ? 'แตะเพื่อโหลดสภาพอากาศ' : 'Tap to load weather',
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.primary),
            ),
          ),
          const Icon(Icons.refresh_rounded, size: 16, color: AppColors.primary),
        ]),
      ),
    );
  }
}

// ─── Main weather card ────────────────────────────────────────────────────────
class _WeatherCard extends StatelessWidget {
  final Weather weather;
  final WeatherPlantTip tip;
  final Color accent;
  final bool isTh;
  final String lang;
  final bool isDark;
  final VoidCallback onRefresh;

  const _WeatherCard({
    required this.weather,
    required this.tip,
    required this.accent,
    required this.isTh,
    required this.lang,
    required this.isDark,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E3028) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSoft = isDark
        ? Colors.white.withOpacity(0.55)
        : const Color(0xFF1A1A2E).withOpacity(0.45);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Weather row ───────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 3))
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
          child: Row(
            children: [
              // Emoji pill
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(11),
                ),
                child:
                    Text(weather.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 11),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(
                          isTh ? weather.conditionThai : weather.conditionEn,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${weather.temperature.toStringAsFixed(0)}°C',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.location_on_rounded,
                          size: 10, color: textSoft),
                      const SizedBox(width: 2),
                      Text(
                        weather.cityName.isNotEmpty
                            ? weather.cityName
                            : (isTh ? 'ตำแหน่งปัจจุบัน' : 'Your Location'),
                        style:
                            GoogleFonts.outfit(fontSize: 10.5, color: textSoft),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.water_drop_rounded, size: 10, color: textSoft),
                      const SizedBox(width: 2),
                      Text(
                        '${weather.humidity.toStringAsFixed(0)}%',
                        style:
                            GoogleFonts.outfit(fontSize: 10.5, color: textSoft),
                      ),
                    ]),
                  ],
                ),
              ),

              // Refresh button
              GestureDetector(
                onTap: onRefresh,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.refresh_rounded, size: 15, color: textSoft),
                ),
              ),
            ],
          ),
        ),

        // ── Tip banner ────────────────────────────────────────────────────
        const SizedBox(height: 7),
        Container(
          padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
          decoration: BoxDecoration(
            color: accent.withOpacity(isDark ? 0.14 : 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withOpacity(0.2), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tip.emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTh ? tip.titleTh : tip.titleEn,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: accent,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isTh ? tip.tipTh : tip.tipEn,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white.withOpacity(0.65)
                            : const Color(0xFF1A1A2E).withOpacity(0.55),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Suggested plants ──────────────────────────────────────────────
        if (tip.suggestedPlantIds.isNotEmpty) ...[
          const SizedBox(height: 10),
          _SuggestedPlants(
            plantIds: tip.suggestedPlantIds,
            lang: lang,
            accent: accent,
            isTh: isTh,
            isDark: isDark,
          ),
        ],
      ],
    );
  }
}

// ─── Suggested plants horizontal row ─────────────────────────────────────────
class _SuggestedPlants extends StatelessWidget {
  final List<String> plantIds;
  final String lang;
  final Color accent;
  final bool isTh;
  final bool isDark;

  const _SuggestedPlants({
    required this.plantIds,
    required this.lang,
    required this.accent,
    required this.isTh,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fav = context.read<FavoriteStore>();
    final water = context.read<WateringStore>();
    final stats = context.read<UserStatsStore>();
    final all = PlantRepository.all();

    final matched = plantIds
        .map((id) {
          try {
            return all.firstWhere((p) => p.id == id);
          } catch (_) {
            return null;
          }
        })
        .whereType<Plant>()
        .toList();

    if (matched.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            isTh ? '🌿 แนะนำวันนี้' : '🌿 Recommended Today',
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: matched.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final plant = matched[i];
              return _PlantChip(
                plant: plant,
                accent: accent,
                isTh: isTh,
                isDark: isDark,
                onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => PlantDetailScreen(
                      plant: plant,
                      fav: fav,
                      water: water,
                      stats: stats,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Mini plant chip ──────────────────────────────────────────────────────────
class _PlantChip extends StatelessWidget {
  final Plant plant;
  final Color accent;
  final bool isTh;
  final bool isDark;
  final VoidCallback onTap;

  const _PlantChip({
    required this.plant,
    required this.accent,
    required this.isTh,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A2820) : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.18), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.12 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                plant.image,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🌿', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                isTh ? plant.nameTh : plant.nameEn,
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withOpacity(0.85)
                      : const Color(0xFF1A1A2E),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
