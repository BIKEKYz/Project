import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/care_data.dart';
import '../../models/plant.dart';
import '../../data/stores/care_store.dart';
import '../../theme/app_colors.dart';

// ─── Smart Alert Logic ────────────────────────────────────────────────────────

enum _AlertLevel { watch, warning, critical }

class _PlantAlert {
  final Plant plant;
  final _AlertLevel level;
  final int daysOverdue;
  final List<String> symptoms;

  _PlantAlert({
    required this.plant,
    required this.level,
    required this.daysOverdue,
    required this.symptoms,
  });
}

List<_PlantAlert> _buildAlerts(
    List<Plant> allPlants, CareStore careStore, List<CareTask> overdueTasks) {
  final alerts = <_PlantAlert>[];
  final now = DateTime.now();

  // Collect overdue plants
  final overdueMap = <String, CareTask>{};
  for (final t in overdueTasks) {
    if (t.type == CareType.water) overdueMap[t.plantId] = t;
  }

  for (final entry in overdueMap.entries) {
    final plant = allPlants.firstWhere((p) => p.id == entry.key,
        orElse: () => allPlants.first);
    final task = entry.value;
    final daysOverdue = now.difference(task.dueDate).inDays.clamp(1, 999);

    // Factor in plant's water interval (drought-tolerant plants get more slack)
    final factor = plant.waterIntervalDays;
    final severity = daysOverdue / factor;

    _AlertLevel level;
    List<String> symptoms;

    if (severity >= 1.5 || daysOverdue >= 6) {
      level = _AlertLevel.critical;
      symptoms = [
        '🍂 ใบร่วงหล่น',
        '🌵 ดินแห้งแตก',
        '💀 รากอาจแห้งตาย',
        '🟤 ลำต้นอ่อนแอ',
      ];
    } else if (severity >= 0.8 || daysOverdue >= 3) {
      level = _AlertLevel.warning;
      symptoms = [
        '🥀 ใบเหี่ยวห้อย',
        '🟡 ปลายใบเหลือง',
        '💧 ดินแห้งมาก',
        '😟 ต้นไม้เครียด',
      ];
    } else {
      level = _AlertLevel.watch;
      symptoms = [
        '🌿 ใบเริ่มอ่อนแรง',
        '🏜️ ดินเริ่มแห้ง',
        '⚠️ ควรรดน้ำเร็วๆ นี้',
      ];
    }

    alerts.add(_PlantAlert(
      plant: plant,
      level: level,
      daysOverdue: daysOverdue,
      symptoms: symptoms,
    ));
  }

  // Sort: critical first
  alerts.sort((a, b) => b.level.index.compareTo(a.level.index));
  return alerts;
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class CareScheduleScreen extends StatelessWidget {
  final CareStore careStore;
  final List<Plant> allPlants;

  const CareScheduleScreen({
    super.key,
    required this.careStore,
    required this.allPlants,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'ตารางดูแล',
          style: GoogleFonts.notoSansThai(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: careStore,
        builder: (context, _) {
          final overdue = careStore.overdueTasks;
          final upcoming = careStore.upcomingTasks;
          final alerts = _buildAlerts(allPlants, careStore, overdue);

          if (overdue.isEmpty && upcoming.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available,
                      size: 64, color: AppColors.primary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('ดูแลครบทุกอย่างแล้ว! 🎉',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 18, color: AppColors.outline)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Smart Alert Banners ──────────────────────────────
              if (alerts.isNotEmpty) ...[
                _SectionHeader(
                  icon: Icons.health_and_safety_outlined,
                  label: 'การแจ้งเตือนสุขภาพ',
                  color: const Color(0xFFE53935),
                ),
                const SizedBox(height: 8),
                ...alerts.map((a) => _AlertBanner(alert: a)),
                const SizedBox(height: 20),
              ],

              // ── Overdue ──────────────────────────────────────────
              if (overdue.isNotEmpty) ...[
                _SectionHeader(
                  icon: Icons.warning_amber_rounded,
                  label: 'เลยกำหนด ⚠️',
                  color: AppColors.error,
                ),
                const SizedBox(height: 8),
                ...overdue.map((t) => _TaskTile(
                      task: t,
                      plant: _findPlant(t.plantId),
                      careStore: careStore,
                      onComplete: () =>
                          careStore.completeTask(t, _findPlant(t.plantId)),
                    )),
                const SizedBox(height: 20),
              ],

              // ── Upcoming ─────────────────────────────────────────
              if (upcoming.isNotEmpty) ...[
                _SectionHeader(
                  icon: Icons.calendar_month_outlined,
                  label: 'กำหนดการถัดไป 📅',
                  color: AppColors.primary,
                ),
                const SizedBox(height: 8),
                ...upcoming.map((t) => _TaskTile(
                      task: t,
                      plant: _findPlant(t.plantId),
                      careStore: careStore,
                      onComplete: () =>
                          careStore.completeTask(t, _findPlant(t.plantId)),
                    )),
              ],

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Plant _findPlant(String id) =>
      allPlants.firstWhere((p) => p.id == id, orElse: () => allPlants.first);
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.notoSansThai(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─── Alert Banner ─────────────────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  final _PlantAlert alert;
  const _AlertBanner({required this.alert});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color textColor;
    final String levelLabel;
    final IconData levelIcon;

    switch (alert.level) {
      case _AlertLevel.critical:
        bg = const Color(0xFFFFF0F0);
        border = const Color(0xFFE53935);
        textColor = const Color(0xFFB71C1C);
        levelLabel = 'วิกฤต';
        levelIcon = Icons.dangerous_outlined;
        break;
      case _AlertLevel.warning:
        bg = const Color(0xFFFFF8E1);
        border = const Color(0xFFFF8F00);
        textColor = const Color(0xFFE65100);
        levelLabel = 'ควรรดน้ำ';
        levelIcon = Icons.warning_amber_rounded;
        break;
      case _AlertLevel.watch:
        bg = const Color(0xFFFFFDE7);
        border = const Color(0xFFFDD835);
        textColor = const Color(0xFFF57F17);
        levelLabel = 'เฝ้าระวัง';
        levelIcon = Icons.info_outline;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(levelIcon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Text(
                alert.plant.nameEn,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: border.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  levelLabel,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Days overdue
          Text(
            'พลาดการรดน้ำ ${alert.daysOverdue} วัน — อาจเกิดอาการ:',
            style: GoogleFonts.notoSansThai(
              fontSize: 12,
              color: textColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),

          // Symptoms wrap
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: alert.symptoms.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border.withOpacity(0.3)),
                ),
                child: Text(
                  s,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12,
                    color: textColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Task Tile ────────────────────────────────────────────────────────────────

class _TaskTile extends StatelessWidget {
  final CareTask task;
  final Plant plant;
  final CareStore careStore;
  final VoidCallback onComplete;

  const _TaskTile({
    required this.task,
    required this.plant,
    required this.careStore,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isOverdue =
        task.dueDate.isBefore(DateTime(now.year, now.month, now.day));

    // Build 7-day history dots
    final dots = <_DotDay>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final logs = careStore.getHistoryForDate(day);
      final watered =
          logs.any((l) => l.plantId == plant.id && l.type == CareType.water);
      final isFuture = day.isAfter(now);
      dots.add(_DotDay(date: day, watered: watered, isFuture: isFuture));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isOverdue
            ? Border.all(color: AppColors.error.withOpacity(0.25))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Type icon
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _getTypeColor(task.type).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getTypeIcon(task.type),
                    color: _getTypeColor(task.type), size: 18),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.nameEn,
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      '${_getTypeName(task.type)} · ${DateFormat('d MMM').format(task.dueDate)}',
                      style: GoogleFonts.notoSansThai(
                        color: isOverdue ? AppColors.error : AppColors.outline,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Complete button
              IconButton(
                onPressed: onComplete,
                icon: Icon(
                  Icons.check_circle_outline,
                  size: 26,
                  color: isOverdue ? AppColors.error : AppColors.outline,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  highlightColor: AppColors.primary.withOpacity(0.1),
                ),
              ),
            ],
          ),

          // ── 7-day watering history dots ──────────────────────
          if (task.type == CareType.water) ...[
            const SizedBox(height: 10),
            _WateringHistoryStrip(dots: dots),
          ],
        ],
      ),
    );
  }

  IconData _getTypeIcon(CareType t) {
    switch (t) {
      case CareType.water:
        return Icons.water_drop;
      case CareType.fertilize:
        return Icons.science;
      case CareType.prune:
        return Icons.content_cut;
      case CareType.repot:
        return Icons.change_circle;
    }
  }

  Color _getTypeColor(CareType t) {
    switch (t) {
      case CareType.water:
        return Colors.blue;
      case CareType.fertilize:
        return Colors.purple;
      case CareType.prune:
        return Colors.orange;
      case CareType.repot:
        return Colors.brown;
    }
  }

  String _getTypeName(CareType t) {
    switch (t) {
      case CareType.water:
        return 'รดน้ำ';
      case CareType.fertilize:
        return 'ใส่ปุ๋ย';
      case CareType.prune:
        return 'ตัดแต่ง';
      case CareType.repot:
        return 'เปลี่ยนกระถาง';
    }
  }
}

// ─── Watering History Strip ───────────────────────────────────────────────────

class _DotDay {
  final DateTime date;
  final bool watered;
  final bool isFuture;
  const _DotDay(
      {required this.date, required this.watered, required this.isFuture});
}

class _WateringHistoryStrip extends StatelessWidget {
  final List<_DotDay> dots;
  const _WateringHistoryStrip({required this.dots});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Row(
      children: [
        Text(
          '7 วัน',
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: AppColors.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dots.map((d) {
              final isToday = d.date.year == now.year &&
                  d.date.month == now.month &&
                  d.date.day == now.day;

              Color dotColor;
              if (d.isFuture) {
                dotColor = Colors.grey.shade200;
              } else if (d.watered) {
                dotColor = const Color(0xFF29B6F6); // blue
              } else {
                dotColor = const Color(0xFFEF9A9A); // light red
              }

              return Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: isToday
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: d.isFuture
                          ? null
                          : Icon(
                              d.watered ? Icons.water_drop : Icons.close,
                              size: 13,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('d').format(d.date),
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      color: isToday ? AppColors.primary : AppColors.outline,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
