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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
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
                    color: AppColors.tertiary.withOpacity(0.2),
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.white54),
                  ),
                ),
              ),

              // Gradient Overlay — light and subtle
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.10),
                      Colors.black.withOpacity(0.62),
                    ],
                    stops: const [0.45, 0.70, 1.0],
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
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plant.nameTh,
                      style: GoogleFonts.notoSansThai(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
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
                top: 10,
                right: 10,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      color: Colors.black.withOpacity(0.15),
                      child: IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? AppColors.error : Colors.white,
                          size: 18,
                        ),
                        onPressed: () {
                          final wasAlreadyFav = fav.isFavorite(plant.id);
                          fav.toggle(plant.id);
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
                          minWidth: 36,
                          minHeight: 36,
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
