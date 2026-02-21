import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/plant.dart';
import '../theme/app_colors.dart';
import '../data/stores/favorite_store.dart';
import '../data/stores/watering_store.dart';
import '../data/stores/user_stats_store.dart';
import '../screens/detail/plant_detail_screen.dart';
import '../data/stores/activity_store.dart';
import 'package:provider/provider.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  final FavoriteStore fav;
  final WateringStore water;
  final UserStatsStore? stats;

  const PlantCard({
    super.key,
    required this.plant,
    required this.fav,
    required this.water,
    this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final isFav = fav.isFavorite(plant.id);
    final lastWater = water.getLastWatered(plant.id);
    final daysLeft = _daysUntilNextWater(lastWater, plant.waterIntervalDays);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlantDetailScreen(
              plant: plant,
              fav: fav,
              water: water,
              stats: stats,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              Hero(
                tag: plant.id,
                child: Image.asset(
                  plant.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.tertiary.withOpacity(0.3),
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.white54),
                  ),
                ),
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.4, 0.7, 1.0],
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      plant.nameEn,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plant.nameTh,
                      style: GoogleFonts.notoSansThai(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (daysLeft <= 0)
                          _StatusChip(
                            label: 'Water Now',
                            color: AppColors.error,
                            icon: Icons.water_drop,
                          )
                        else
                          _StatusChip(
                            label: '$daysLeft days',
                            color: AppColors.secondary,
                            icon: Icons.schedule,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Favorite Button
              Positioned(
                top: 12,
                right: 12,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      color: Colors.black.withOpacity(0.2),
                      child: IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? AppColors.error : Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          final wasAlreadyFav = fav.isFavorite(plant.id);
                          fav.toggle(plant.id);
                          // Log to activity store
                          try {
                            final activityStore = Provider.of<ActivityStore>(
                                context,
                                listen: false);
                            activityStore.logFavorite(
                              plant.id,
                              plant.nameEn,
                              '🌿',
                              !wasAlreadyFav,
                            );
                          } catch (_) {}
                        },
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _daysUntilNextWater(DateTime? lastWatered, int interval) {
    if (lastWatered == null) return 0;
    final next = lastWatered.add(Duration(days: interval));
    final diff = next.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
