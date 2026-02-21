import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/care_data.dart';
import '../../models/plant.dart';
import '../../data/stores/care_store.dart';
import '../../theme/app_colors.dart';

// ─── Smart Alert Logic (shared) ───────────────────────────────────────────────

enum _AlertLevel { watch, warning, critical }

class _PlantAlert {
  final Plant plant;
  final _AlertLevel level;
  final int daysOverdue;
  final double healthScore;
  final List<String> symptoms;

  _PlantAlert({
    required this.plant,
    required this.level,
    required this.daysOverdue,
    required this.healthScore,
    required this.symptoms,
  });
}

List<_PlantAlert> _buildAlerts(List<Plant> allPlants, CareStore careStore) {
  final alerts = <_PlantAlert>[];
  final now = DateTime.now();
  final overdue =
      careStore.overdueTasks.where((t) => t.type == CareType.water).toList();

  final seen = <String>{};
  for (final task in overdue) {
    if (seen.contains(task.plantId)) continue;
    seen.add(task.plantId);

    final plant = allPlants.firstWhere((p) => p.id == task.plantId,
        orElse: () => allPlants.first);
    final daysOverdue = now.difference(task.dueDate).inDays.clamp(1, 999);
    final status = careStore.getPlantStatus(task.plantId);
    final healthScore = status?.healthScore ?? 50.0;
    final severity = daysOverdue / plant.waterIntervalDays;

    _AlertLevel level;
    List<String> symptoms;

    if (severity >= 1.5 || daysOverdue >= 6 || healthScore < 20) {
      level = _AlertLevel.critical;
      symptoms = [
        '🍂 ใบร่วงหล่น',
        '🌵 ดินแห้งแตก',
        '💀 รากอาจแห้งตาย',
        '🟤 ลำต้นอ่อนแอ',
      ];
    } else if (severity >= 0.8 || daysOverdue >= 3 || healthScore < 40) {
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
      healthScore: healthScore,
      symptoms: symptoms,
    ));
  }

  alerts.sort((a, b) => b.level.index.compareTo(a.level.index));
  return alerts;
}

// ─── Calendar Screen ──────────────────────────────────────────────────────────

class CareCalendarScreen extends StatefulWidget {
  final CareStore careStore;
  final List<Plant> allPlants;

  const CareCalendarScreen({
    super.key,
    required this.careStore,
    required this.allPlants,
  });

  @override
  State<CareCalendarScreen> createState() => _CareCalendarScreenState();
}

class _CareCalendarScreenState extends State<CareCalendarScreen> {
  late DateTime _focusMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _focusMonth = DateTime.now();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'ปฏิทินการดูแล',
          style: GoogleFonts.notoSansThai(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: widget.careStore,
        builder: (context, _) {
          final alerts = _buildAlerts(widget.allPlants, widget.careStore);
          final selectedLogs = _selectedDate != null
              ? widget.careStore.getHistoryForDate(_selectedDate!)
              : <CareLog>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Health Alert Section ─────────────────────────────
              if (alerts.isNotEmpty) ...[
                _SectionLabel(
                  icon: Icons.health_and_safety_outlined,
                  label: 'แจ้งเตือนสุขภาพต้นไม้',
                  color: const Color(0xFFE53935),
                ),
                const SizedBox(height: 8),
                ...alerts.map((a) => _AlertCard(alert: a)),
                const SizedBox(height: 16),
              ],

              // ── Mini Calendar ────────────────────────────────────
              _SectionLabel(
                icon: Icons.calendar_month_outlined,
                label: DateFormat('MMMM yyyy').format(_focusMonth),
                color: AppColors.primary,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NavBtn(
                      icon: Icons.chevron_left,
                      onTap: () => setState(() {
                        _focusMonth =
                            DateTime(_focusMonth.year, _focusMonth.month - 1);
                      }),
                    ),
                    _NavBtn(
                      icon: Icons.chevron_right,
                      onTap: () => setState(() {
                        _focusMonth =
                            DateTime(_focusMonth.year, _focusMonth.month + 1);
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _MiniCalendar(
                focusMonth: _focusMonth,
                careStore: widget.careStore,
                selectedDate: _selectedDate,
                onDateSelected: (d) => setState(() => _selectedDate = d),
              ),
              const SizedBox(height: 20),

              // ── Selected Day Activity ────────────────────────────
              if (_selectedDate != null) ...[
                _SectionLabel(
                  icon: Icons.event_note_outlined,
                  label:
                      'กิจกรรม ${DateFormat('d MMMM').format(_selectedDate!)}',
                  color: AppColors.primary,
                ),
                const SizedBox(height: 8),
                if (selectedLogs.isEmpty)
                  _EmptyDayCard()
                else
                  ...selectedLogs.map((log) => _LogTile(
                        log: log,
                        plant: _findPlant(log.plantId),
                      )),
                const SizedBox(height: 20),
              ],

              // ── Monthly History ──────────────────────────────────
              _SectionLabel(
                icon: Icons.history_outlined,
                label: 'ประวัติเดือนนี้',
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              _MonthlyHistoryList(
                careStore: widget.careStore,
                allPlants: widget.allPlants,
                month: _focusMonth,
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Plant _findPlant(String id) => widget.allPlants
      .firstWhere((p) => p.id == id, orElse: () => widget.allPlants.first);
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Widget? trailing;
  const _SectionLabel(
      {required this.icon,
      required this.label,
      required this.color,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.notoSansThai(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}

// ─── Mini Calendar Grid ───────────────────────────────────────────────────────

class _MiniCalendar extends StatelessWidget {
  final DateTime focusMonth;
  final CareStore careStore;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _MiniCalendar({
    required this.focusMonth,
    required this.careStore,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(focusMonth.year, focusMonth.month, 1);
    final daysInMonth = DateTime(focusMonth.year, focusMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    final monthLogs =
        careStore.getHistoryForMonth(focusMonth.year, focusMonth.month);
    // Map day -> has watered
    final wateredDays = <int>{};
    final anyCareDays = <int>{};
    for (final log in monthLogs) {
      anyCareDays.add(log.date.day);
      if (log.type == CareType.water) wateredDays.add(log.date.day);
    }

    // Overdue days (past days in this month with no care)
    final overdueDays = <int>{};
    final today = DateTime(now.year, now.month, now.day);
    if (focusMonth.year == now.year && focusMonth.month == now.month) {
      for (int d = 1; d < now.day; d++) {
        if (!anyCareDays.contains(d)) overdueDays.add(d);
      }
    } else if (focusMonth.isBefore(DateTime(now.year, now.month))) {
      for (int d = 1; d <= daysInMonth; d++) {
        if (!anyCareDays.contains(d)) overdueDays.add(d);
      }
    }

    const weekLabels = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Week day labels
          Row(
            children: weekLabels.map((w) {
              return Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.outline,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Day grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 2,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday) return const SizedBox();
              final day = index - startWeekday + 1;
              final date = DateTime(focusMonth.year, focusMonth.month, day);
              final isToday = date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;
              final isSelected = selectedDate != null &&
                  date.year == selectedDate!.year &&
                  date.month == selectedDate!.month &&
                  date.day == selectedDate!.day;
              final isFuture = date.isAfter(today);
              final hasWater = wateredDays.contains(day);
              final isOverdue = overdueDays.contains(day);

              return GestureDetector(
                onTap: () => onDateSelected(date),
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: isToday || isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : isFuture
                                  ? AppColors.outline.withOpacity(0.4)
                                  : const Color(0xFF1A1A1A),
                        ),
                      ),
                      // Dot indicator
                      if (!isFuture)
                        Positioned(
                          bottom: 3,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasWater)
                                _Dot(color: const Color(0xFF29B6F6)),
                              if (isOverdue && !hasWater)
                                _Dot(color: const Color(0xFFEF5350)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Legend
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: const Color(0xFF29B6F6), label: 'รดน้ำแล้ว'),
              const SizedBox(width: 16),
              _LegendItem(color: const Color(0xFFEF5350), label: 'พลาด'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.notoSansThai(
            fontSize: 11,
            color: AppColors.outline,
          ),
        ),
      ],
    );
  }
}

// ─── Alert Card ───────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final _PlantAlert alert;
  const _AlertCard({required this.alert});

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
          Row(
            children: [
              Icon(levelIcon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  alert.plant.nameEn,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
              // Health score chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: border.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$levelLabel · ${alert.healthScore.toInt()}%',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'พลาดรดน้ำ ${alert.daysOverdue} วัน — อาจเกิดอาการ:',
            style: GoogleFonts.notoSansThai(
              fontSize: 12,
              color: textColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
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

// ─── Log Tile ─────────────────────────────────────────────────────────────────

class _LogTile extends StatelessWidget {
  final CareLog log;
  final Plant plant;
  const _LogTile({required this.log, required this.plant});

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(log.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_typeIcon(log.type), color: typeColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.nameEn,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  _typeName(log.type),
                  style: GoogleFonts.notoSansThai(
                      color: AppColors.outline, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm').format(log.date),
            style: GoogleFonts.outfit(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(CareType t) {
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

  Color _typeColor(CareType t) {
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

  String _typeName(CareType t) {
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

// ─── Empty Day Card ───────────────────────────────────────────────────────────

class _EmptyDayCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_busy_outlined,
                size: 36, color: AppColors.outline.withOpacity(0.3)),
            const SizedBox(height: 8),
            Text(
              'ไม่มีกิจกรรมในวันนี้',
              style: GoogleFonts.notoSansThai(
                  fontSize: 14, color: AppColors.outline),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Monthly History List ─────────────────────────────────────────────────────

class _MonthlyHistoryList extends StatelessWidget {
  final CareStore careStore;
  final List<Plant> allPlants;
  final DateTime month;

  const _MonthlyHistoryList({
    required this.careStore,
    required this.allPlants,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final logs = careStore.getHistoryForMonth(month.year, month.month);

    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_busy,
                  size: 40, color: AppColors.outline.withOpacity(0.25)),
              const SizedBox(height: 10),
              Text(
                'ไม่มีกิจกรรมในเดือนนี้',
                style: GoogleFonts.notoSansThai(
                    fontSize: 14, color: AppColors.outline),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: logs.map((log) {
        final plant = allPlants.firstWhere((p) => p.id == log.plantId,
            orElse: () => allPlants.first);
        return _LogTileWithDate(log: log, plant: plant);
      }).toList(),
    );
  }
}

class _LogTileWithDate extends StatelessWidget {
  final CareLog log;
  final Plant plant;
  const _LogTileWithDate({required this.log, required this.plant});

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(log.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_typeIcon(log.type), color: typeColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.nameEn,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  _typeName(log.type),
                  style: GoogleFonts.notoSansThai(
                      color: AppColors.outline, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('d MMM').format(log.date),
                style: GoogleFonts.outfit(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('HH:mm').format(log.date),
                style: GoogleFonts.outfit(
                    color: AppColors.outline,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(CareType t) {
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

  Color _typeColor(CareType t) {
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

  String _typeName(CareType t) {
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
