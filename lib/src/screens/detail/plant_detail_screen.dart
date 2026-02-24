import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/plant.dart';
import '../../models/care_data.dart';
import '../../theme/app_colors.dart';
import '../../data/stores/favorite_store.dart';
import '../../data/stores/watering_store.dart';
import '../../data/stores/user_stats_store.dart';
import '../../data/stores/care_store.dart';
import '../../widgets/confetti_overlay.dart';
import '../../data/stores/activity_store.dart';
import 'package:provider/provider.dart';

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;
  final FavoriteStore? fav;
  final WateringStore? water;
  final UserStatsStore? stats;
  final CareStore? careStore;

  const PlantDetailScreen({
    super.key,
    required this.plant,
    this.fav,
    this.water,
    this.stats,
    this.careStore,
  });

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final ConfettiController _confetti = ConfettiController();

  @override
  Widget build(BuildContext context) {
    final isFav = widget.fav?.isFavorite(widget.plant.id) ?? false;

    return ConfettiOverlay(
      controller: _confetti,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 400,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                if (widget.fav != null)
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? AppColors.error : Colors.white,
                    ),
                    onPressed: () => widget.fav!.toggle(widget.plant.id),
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: widget.plant.id,
                      child: Image.asset(
                        widget.plant.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: AppColors.tertiary),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.transparent,
                            AppColors.background,
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.plant.nameEn,
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            widget.plant.scientific,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: AppColors.primary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.plant.tags.map((t) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.secondary.withOpacity(0.3)),
                          ),
                          child: Text(
                            t,
                            style: GoogleFonts.notoSansThai(
                              color: AppColors.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Description
                    Text(
                      widget.plant.description,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Quick Facts
                    Text(
                      'Quick Facts',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _FactTile(
                          icon: Icons.thermostat,
                          label: 'Temp',
                          value: widget.plant.temperature,
                        ),
                        _FactTile(
                          icon: Icons.water_drop,
                          label: 'Humidity',
                          value: widget.plant.humidity,
                        ),
                        _FactTile(
                          icon: Icons.grass,
                          label: 'Soil',
                          value: widget.plant.soil,
                        ),
                        _FactTile(
                          icon: Icons.warning_amber_rounded,
                          label: 'Toxicity',
                          value: widget.plant.toxicity,
                          isWarning: widget.plant.toxicity.contains('Toxic'),
                        ),
                        _FactTile(
                          icon: Icons.schedule,
                          label: 'Lifespan',
                          value: widget.plant.lifespan,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Care Guide
                    Text(
                      'Care Guide',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CareTile(
                      icon: Icons.wb_sunny_outlined,
                      title: 'Light',
                      subtitle: _lightText(widget.plant.light),
                      description: 'Ensure proper lighting for optimal growth.',
                    ),
                    _CareTile(
                      icon: Icons.water_drop_outlined,
                      title: 'Water',
                      subtitle: 'Every ${widget.plant.waterIntervalDays} days',
                      description: 'Check soil moisture before watering.',
                    ),
                    _CareTile(
                      icon: Icons.thermostat_outlined,
                      title: 'Difficulty',
                      subtitle: _diffText(widget.plant.difficulty),
                      description: 'Suitable for your experience level.',
                    ),

                    const SizedBox(height: 32),

                    // Pests & Diseases
                    Text(
                      'ศัตรูพืชและโรคพืช',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.bug_report,
                            color: AppColors.error,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ศัตรูพืชที่พบบ่อย',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.plant.pests,
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.healing,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'โรคพืชที่พบบ่อย',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.plant.diseases,
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Leaf Warning Signs
                    Text(
                      'สัญญาณเตือนจากใบ',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.secondary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.secondary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.plant.leafWarnings,
                              style: GoogleFonts.notoSansThai(
                                fontSize: 14,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Care History
                    if (widget.careStore != null) ...[
                      Text(
                        'Care History',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListenableBuilder(
                        listenable: widget.careStore!,
                        builder: (context, _) {
                          final history = widget.careStore!.history
                              .where((h) => h.plantId == widget.plant.id)
                              .take(5)
                              .toList();

                          if (history.isEmpty) {
                            return Text(
                              'No care history yet.',
                              style: GoogleFonts.notoSansThai(
                                  color: AppColors.outline),
                            );
                          }

                          return Column(
                            children: history
                                .map((log) => ListTile(
                                      leading: Icon(Icons.check_circle,
                                          color: AppColors.secondary),
                                      title: Text(_getTypeName(log.type)),
                                      subtitle: Text(
                                          DateFormat('MMM d, y • h:mm a')
                                              .format(log.date)),
                                      contentPadding: EdgeInsets.zero,
                                    ))
                                .toList(),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 100), // Space for FAB
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: ListenableBuilder(
          listenable: Listenable.merge([
            if (widget.water != null) widget.water!,
            if (widget.careStore != null) widget.careStore!,
          ]),
          builder: (context, _) {
            // Check if can water today using CareStore
            final canWater =
                widget.careStore?.canWaterToday(widget.plant.id) ?? true;

            return FloatingActionButton.extended(
              onPressed: widget.water != null
                  ? () async {
                      // Only water if this is first watering today
                      if (canWater) {
                        HapticFeedback.mediumImpact();
                        await widget.water!.setNow(widget.plant.id);

                        // Log to activity store
                        try {
                          final activityStore = Provider.of<ActivityStore>(
                              context,
                              listen: false);
                          activityStore.logWatered(
                            widget.plant.id,
                            widget.plant.nameEn,
                            '💧',
                          );
                        } catch (_) {}

                        _confetti.play();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Plant watered! 💧')),
                          );
                        }
                      } else {
                        // Already watered today
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Already watered today! 💧\nCome back tomorrow'),
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                        }
                      }
                    }
                  : null,
              backgroundColor: canWater ? AppColors.primary : AppColors.outline,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: Icon(canWater ? Icons.water_drop : Icons.check_circle),
              label: Text(canWater ? 'Water Plant' : 'Watered Today'),
            );
          },
        ),
      ),
    );
  }

  String _lightText(Light l) {
    switch (l) {
      case Light.low:
        return 'Low Light';
      case Light.medium:
        return 'Indirect Light';
      case Light.bright:
        return 'Bright Light';
    }
  }

  String _diffText(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return 'Beginner Friendly';
      case Difficulty.medium:
        return 'Intermediate';
      case Difficulty.hard:
        return 'Expert';
    }
  }

  String _getTypeName(CareType t) {
    switch (t) {
      case CareType.water:
        return 'Watered';
      case CareType.fertilize:
        return 'Fertilized';
      case CareType.prune:
        return 'Pruned';
      case CareType.repot:
        return 'Repotted';
    }
  }
}

class _FactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isWarning;

  const _FactTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWarning
            ? AppColors.error.withOpacity(0.1)
            : AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWarning
              ? AppColors.error.withOpacity(0.3)
              : AppColors.secondary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: isWarning ? AppColors.error : AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CareTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;

  const _CareTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12,
                    color: AppColors.outline,
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
