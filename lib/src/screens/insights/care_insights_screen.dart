import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/stores/care_store.dart';
import '../../models/plant.dart';
import '../../theme/app_colors.dart';

class CareInsightsScreen extends StatelessWidget {
  final CareStore careStore;
  final List<Plant> allPlants;

  const CareInsightsScreen({
    super.key,
    required this.careStore,
    required this.allPlants,
  });

  @override
  Widget build(BuildContext context) {
    final achievements = careStore.achievements;
    final topStreaks = careStore.getTopStreakPlants();
    final avgHealth = careStore.averageHealthScore;
    final totalStreak = careStore.totalCareStreak;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Care Insights',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          IconButton(
            onPressed: () => _showAchievementsDialog(context),
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Achievements',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header stats cards
            _buildStatsRow(
              context,
              totalStreak: totalStreak,
              avgHealth: avgHealth,
              totalAchievements: achievements.length,
            ),

            const SizedBox(height: 24),

            // Chart section
            _buildChartSection(context),

            const SizedBox(height: 24),

            // Top streak plants
            _buildTopStreakSection(context, topStreaks),

            const SizedBox(height: 24),

            // Recent achievements
            _buildRecentAchievements(context, achievements),

            const SizedBox(height: 24),

            // Weekly activity
            _buildWeeklyActivity(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context, {
    required int totalStreak,
    required double avgHealth,
    required int totalAchievements,
  }) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: '🔥',
            title: 'Best Streak',
            value: '$totalStreak',
            subtitle: 'days',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: '💚',
            title: 'Avg Health',
            value: '${avgHealth.round()}',
            subtitle: 'score',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: '🏆',
            title: 'Achievements',
            value: '$totalAchievements',
            subtitle: 'unlocked',
            color: Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Activity',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  _ChartLegend(color: AppColors.primary, label: 'Water'),
                  const SizedBox(width: 12),
                  _ChartLegend(color: Colors.purple, label: 'Fertilize'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: _SimpleBarChart(careStore: careStore),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStreakSection(
      BuildContext context, List<MapEntry<String, int>> topStreaks) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                'Top Streak Plants',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (topStreaks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Start caring for your plants to build streaks!',
                  style: GoogleFonts.outfit(color: Colors.grey),
                ),
              ),
            )
          else
            ...topStreaks.take(5).map((entry) {
              final plant = allPlants.firstWhere(
                (p) => p.id == entry.key,
                orElse: () => allPlants.first,
              );
              return _StreakPlantTile(
                plant: plant,
                streak: entry.value,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRecentAchievements(BuildContext context, List achievements) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Achievements',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => _showAchievementsDialog(context),
                child: Text('View All', style: GoogleFonts.outfit()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (achievements.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      'Complete tasks to unlock achievements!',
                      style: GoogleFonts.outfit(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: achievements.take(6).map((achievement) {
                return _AchievementBadge(achievement: achievement);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyActivity(BuildContext context) {
    final now = DateTime.now();
    final weekDays =
        List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7-Day Activity',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((day) {
              final history = careStore.getHistoryForDate(day);
              final hasActivity = history.isNotEmpty;
              return _DayActivityDot(
                day: ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1],
                active: hasActivity,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showAchievementsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Text(
                    'Achievements',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: careStore.achievements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🎯', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 16),
                            Text(
                              'No achievements yet',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start caring for your plants!',
                              style:
                                  GoogleFonts.outfit(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        children: careStore.achievements.map((achievement) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.amber.withOpacity(0.2),
                              child: Text(
                                achievement.icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            title: Text(
                              achievement.titleThai,
                              style: GoogleFonts.notoSansThai(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              achievement.descriptionThai,
                              style: GoogleFonts.notoSansThai(),
                            ),
                            trailing: Text(
                              _formatDate(achievement.unlockedAt),
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Close', style: GoogleFonts.outfit()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final CareStore careStore;

  const _SimpleBarChart({required this.careStore});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekDays =
        List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: weekDays.map((day) {
        final history = careStore.getHistoryForDate(day);
        final waters = history.where((h) => h.type == CareType.water).length;
        final fertilizes =
            history.where((h) => h.type == CareType.fertilize).length;

        return _BarGroup(
          day: ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1],
          waterCount: waters,
          fertilizeCount: fertilizes,
        );
      }).toList(),
    );
  }
}

class CareType {
  static Object? get fertilize => null;

  static Object? get water => null;
}

class _BarGroup extends StatelessWidget {
  final String day;
  final int waterCount;
  final int fertilizeCount;

  const _BarGroup({
    required this.day,
    required this.waterCount,
    required this.fertilizeCount,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = 100.0;
    final waterHeight = waterCount * 20.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (waterHeight > 0)
          Container(
            width: 24,
            height: waterHeight.clamp(10, maxHeight),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
          )
        else
          Container(
            width: 24,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          day,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StreakPlantTile extends StatelessWidget {
  final Plant plant;
  final int streak;

  const _StreakPlantTile({
    required this.plant,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              plant.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.local_florist,
                size: 30,
                color: Colors.green,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.nameEn,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  plant.nameTh,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$streak',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
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

class _AchievementBadge extends StatelessWidget {
  final dynamic achievement;

  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            achievement.icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 6),
          Text(
            achievement.titleThai,
            style: GoogleFonts.notoSansThai(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DayActivityDot extends StatelessWidget {
  final String day;
  final bool active;

  const _DayActivityDot({required this.day, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? Colors.green : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: active
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
