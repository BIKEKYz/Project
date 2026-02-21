import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/plant.dart';
import '../models/care_data.dart';
import '../data/stores/care_store.dart';
import '../theme/app_colors.dart';
import '../screens/detail/plant_detail_screen.dart';

class ProfessionalPlantCard extends StatelessWidget {
  final Plant plant;
  final CareStore careStore;
  final VoidCallback? onFavoriteToggle;

  const ProfessionalPlantCard({
    super.key,
    required this.plant,
    required this.careStore,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final status = careStore.getPlantStatus(plant.id);
    final canWater = careStore.canWaterToday(plant.id);
    final lastWatered = careStore.getLastWateredTime(plant.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlantDetailScreen(plant: plant),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlay badges
            Stack(
              children: [
                // Plant image
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Hero(
                    tag: 'plant-${plant.id}',
                    child: Image.network(
                      plant.imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Gradient overlay
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),

                // Top badges row
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      // Health score badge
                      if (status != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: status.healthColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${status.healthScore.round()}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),

                      // Streak badge
                      if (status != null && status.careStreak > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                '${status.careStreak}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const Spacer(),

                      // Favorite button
                      GestureDetector(
                        onTap: onFavoriteToggle,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Plant name at bottom
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.nameEn,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        plant.nameTh,
                        style: GoogleFonts.notoSansThai(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Watering status
                  Row(
                    children: [
                      Icon(
                        Icons.water_drop,
                        color: canWater ? AppColors.primary : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          canWater
                              ? 'Ready to water'
                              : lastWatered != null
                                  ? 'Watered today at ${_formatTime(lastWatered)}'
                                  : 'Not watered yet',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: canWater
                                ? AppColors.textPrimary
                                : Colors.grey[600],
                            fontWeight:
                                canWater ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (!canWater)
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 18),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Health status bar
                  if (status != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Health',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          status.healthLabelThai,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 12,
                            color: status.healthColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: status.healthScore / 100,
                        backgroundColor: Colors.grey[200],
                        color: status.healthColor,
                        minHeight: 8,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Quick actions
                  Row(
                    children: [
                      _QuickActionButton(
                        icon: Icons.water_drop,
                        label: 'Water',
                        color: AppColors.primary,
                        enabled: canWater,
                        onTap:
                            canWater ? () => _handleQuickWater(context) : null,
                      ),
                      const SizedBox(width: 8),
                      _QuickActionButton(
                        icon: Icons.science,
                        label: 'Fertilize',
                        color: Colors.purple,
                        enabled: careStore.canFertilizeToday(plant.id),
                        onTap: careStore.canFertilizeToday(plant.id)
                            ? () => _handleQuickFertilize(context)
                            : null,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlantDetailScreen(plant: plant),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: Text(
                          'Details',
                          style: GoogleFonts.outfit(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleQuickWater(BuildContext context) {
    // Quick water action
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Water ${plant.nameEn}?', style: GoogleFonts.outfit()),
        content: Text(
          'This will complete the watering task and start a new care streak!',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Find and complete water task
              final task = careStore.tasks.firstWhere(
                (t) => t.plantId == plant.id && t.type == CareType.water,
                orElse: () => CareTask(
                  id: '',
                  plantId: plant.id,
                  type: CareType.water,
                  dueDate: DateTime.now(),
                ),
              );
              careStore.completeTask(task, plant);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🌱 ${plant.nameEn} watered successfully!'),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () => careStore.undoLastAction(),
                  ),
                ),
              );
            },
            child: const Text('Water Now'),
          ),
        ],
      ),
    );
  }

  void _handleQuickFertilize(BuildContext context) {
    // Similar to water
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Fertilize ${plant.nameEn}?', style: GoogleFonts.outfit()),
        content: Text(
          'Give your plant the nutrients it needs!',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final task = careStore.tasks.firstWhere(
                (t) => t.plantId == plant.id && t.type == CareType.fertilize,
                orElse: () => CareTask(
                  id: '',
                  plantId: plant.id,
                  type: CareType.fertilize,
                  dueDate: DateTime.now(),
                ),
              );
              careStore.completeTask(task, plant);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🌿 ${plant.nameEn} fertilized!'),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () => careStore.undoLastAction(),
                  ),
                ),
              );
            },
            child: const Text('Fertilize Now'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: (enabled ? color : Colors.grey).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (enabled ? color : Colors.grey).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: enabled ? color : Colors.grey, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: enabled ? color : Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
