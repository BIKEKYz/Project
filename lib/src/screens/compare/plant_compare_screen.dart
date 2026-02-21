import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/plant.dart';
import '../../theme/app_colors.dart';
import '../../data/plant_repository.dart';

class PlantCompareScreen extends StatefulWidget {
  final Plant? initialPlant;
  const PlantCompareScreen({super.key, this.initialPlant});

  @override
  State<PlantCompareScreen> createState() => _PlantCompareScreenState();
}

class _PlantCompareScreenState extends State<PlantCompareScreen> {
  final _all = PlantRepository.all();
  Plant? _left;
  Plant? _right;

  @override
  void initState() {
    super.initState();
    _left = widget.initialPlant;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '🔍 เปรียบเทียบต้นไม้',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Selector row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _PlantSelector(
                    plant: _left,
                    label: 'ต้นไม้ที่ 1',
                    all: _all,
                    exclude: _right,
                    onSelect: (p) => setState(() => _left = p),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.compare_arrows,
                        color: AppColors.primary, size: 20),
                  ),
                ),
                Expanded(
                  child: _PlantSelector(
                    plant: _right,
                    label: 'ต้นไม้ที่ 2',
                    all: _all,
                    exclude: _left,
                    onSelect: (p) => setState(() => _right = p),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Compare body
          if (_left == null || _right == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌿', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    Text(
                      'เลือกต้นไม้ 2 ชนิดเพื่อเปรียบเทียบ',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 15,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _CompareTable(left: _left!, right: _right!),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Plant Selector Card ──────────────────────────────────────────────────────

class _PlantSelector extends StatelessWidget {
  final Plant? plant;
  final String label;
  final List<Plant> all;
  final Plant? exclude;
  final ValueChanged<Plant> onSelect;

  const _PlantSelector({
    required this.plant,
    required this.label,
    required this.all,
    required this.onSelect,
    this.exclude,
  });

  void _pick(BuildContext context) async {
    final result = await showModalBottomSheet<Plant>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlantPickerSheet(all: all, exclude: exclude),
    );
    if (result != null) onSelect(result);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: plant != null
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.outline.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: plant == null
            ? Column(
                children: [
                  const Icon(Icons.add_circle_outline,
                      color: AppColors.primary, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.outline,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      plant!.image,
                      height: 72,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 72,
                        color: AppColors.tertiary,
                        child: const Icon(Icons.local_florist,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plant!.nameTh,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    plant!.nameEn,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: AppColors.outline,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Plant Picker Sheet ───────────────────────────────────────────────────────

class _PlantPickerSheet extends StatefulWidget {
  final List<Plant> all;
  final Plant? exclude;
  const _PlantPickerSheet({required this.all, this.exclude});

  @override
  State<_PlantPickerSheet> createState() => _PlantPickerSheetState();
}

class _PlantPickerSheetState extends State<_PlantPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.all
        .where((p) =>
            p != widget.exclude &&
            (p.nameTh.contains(_q) ||
                p.nameEn.toLowerCase().contains(_q.toLowerCase())))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'ค้นหาต้นไม้...',
                filled: true,
                fillColor: AppColors.background,
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = filtered[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      p.image,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: AppColors.tertiary,
                        child: const Icon(Icons.local_florist,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  title: Text(
                    p.nameTh,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  subtitle: Text(
                    p.nameEn,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.outline,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CompareTable ─────────────────────────────────────────────────────────────

class _CompareTable extends StatelessWidget {
  final Plant left;
  final Plant right;
  const _CompareTable({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();
    return Column(
      children: [
        // Header
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  left.nameTh,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 60),
              Expanded(
                child: Text(
                  right.nameTh,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        // Rows
        ...rows.map((r) => _CompareRow(
              label: r.label,
              leftVal: r.leftVal,
              rightVal: r.rightVal,
              leftWins: r.leftWins,
              rightWins: r.rightWins,
              isEmoji: r.isEmoji,
            )),

        const SizedBox(height: 16),

        // Winner banner
        _WinnerBanner(left: left, right: right, rows: rows),
      ],
    );
  }

  List<_RowData> _buildRows() => [
        _RowData(
          label: '🌿 ประเภท / ขนาด',
          leftVal: _sizeText(left.size),
          rightVal: _sizeText(right.size),
        ),
        _RowData(
          label: '☀️ แสงที่ต้องการ',
          leftVal: _lightText(left.light),
          rightVal: _lightText(right.light),
        ),
        _RowData(
          label: '⭐ ความยาก',
          leftVal: _diffText(left.difficulty),
          rightVal: _diffText(right.difficulty),
          leftWins: left.difficulty.index < right.difficulty.index,
          rightWins: right.difficulty.index < left.difficulty.index,
          lowerIsBetter: true,
        ),
        _RowData(
          label: '💧 รดน้ำทุก (วัน)',
          leftVal: '${left.waterIntervalDays} วัน',
          rightVal: '${right.waterIntervalDays} วัน',
          leftWins: left.waterIntervalDays > right.waterIntervalDays,
          rightWins: right.waterIntervalDays > left.waterIntervalDays,
        ),
        _RowData(
          label: '🐾 ปลอดภัยต่อสัตว์',
          leftVal: left.petSafe ? '✅ ปลอดภัย' : '❌ ไม่ปลอดภัย',
          rightVal: right.petSafe ? '✅ ปลอดภัย' : '❌ ไม่ปลอดภัย',
          leftWins: left.petSafe && !right.petSafe,
          rightWins: right.petSafe && !left.petSafe,
          isEmoji: true,
        ),
        _RowData(
          label: '💨 ฟอกอากาศ',
          leftVal: left.airPurifying ? '✅ ใช่' : '❌ ไม่',
          rightVal: right.airPurifying ? '✅ ใช่' : '❌ ไม่',
          leftWins: left.airPurifying && !right.airPurifying,
          rightWins: right.airPurifying && !left.airPurifying,
          isEmoji: true,
        ),
        _RowData(
          label: '🌡️ อุณหภูมิ',
          leftVal: left.temperature,
          rightVal: right.temperature,
        ),
        _RowData(
          label: '💦 ความชื้น',
          leftVal: left.humidity,
          rightVal: right.humidity,
        ),
        _RowData(
          label: '🌱 ดินที่เหมาะสม',
          leftVal: left.soil,
          rightVal: right.soil,
        ),
        _RowData(
          label: '⚠️ ความเป็นพิษ',
          leftVal: left.toxicity,
          rightVal: right.toxicity,
        ),
      ];

  String _sizeText(SizeClass s) {
    switch (s) {
      case SizeClass.tiny:
        return 'ขนาดจิ๋ว';
      case SizeClass.small:
        return 'ขนาดเล็ก';
      case SizeClass.medium:
        return 'ขนาดกลาง/ใหญ่';
    }
  }

  String _lightText(Light l) {
    switch (l) {
      case Light.low:
        return 'แสงน้อย';
      case Light.medium:
        return 'แสงกลาง';
      case Light.bright:
        return 'แสงจ้า';
    }
  }

  String _diffText(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return '🟢 ง่าย';
      case Difficulty.medium:
        return '🟡 ปานกลาง';
      case Difficulty.hard:
        return '🔴 ยาก';
    }
  }
}

class _RowData {
  final String label;
  final String leftVal;
  final String rightVal;
  final bool leftWins;
  final bool rightWins;
  final bool isEmoji;
  final bool lowerIsBetter;

  const _RowData({
    required this.label,
    required this.leftVal,
    required this.rightVal,
    this.leftWins = false,
    this.rightWins = false,
    this.isEmoji = false,
    this.lowerIsBetter = false,
  });

  int get score => (leftWins ? 1 : 0) - (rightWins ? 1 : 0);
}

class _CompareRow extends StatelessWidget {
  final String label;
  final String leftVal;
  final String rightVal;
  final bool leftWins;
  final bool rightWins;
  final bool isEmoji;

  const _CompareRow({
    required this.label,
    required this.leftVal,
    required this.rightVal,
    required this.leftWins,
    required this.rightWins,
    required this.isEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Label header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          // Values
          IntrinsicHeight(
            child: Row(
              children: [
                // Left
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: leftWins
                        ? BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(14),
                            ),
                          )
                        : const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(14),
                            ),
                          ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (leftWins)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.star_rounded,
                                color: Color(0xFF2E7D32), size: 14),
                          ),
                        Flexible(
                          child: Text(
                            leftVal,
                            style: GoogleFonts.notoSansThai(
                              fontSize: 12,
                              fontWeight: leftWins
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: leftWins
                                  ? const Color(0xFF2E7D32)
                                  : AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Divider
                Container(width: 1, color: AppColors.background),
                // Right
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: rightWins
                        ? BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(14),
                            ),
                          )
                        : const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(14),
                            ),
                          ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (rightWins)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.star_rounded,
                                color: Color(0xFF2E7D32), size: 14),
                          ),
                        Flexible(
                          child: Text(
                            rightVal,
                            style: GoogleFonts.notoSansThai(
                              fontSize: 12,
                              fontWeight: rightWins
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: rightWins
                                  ? const Color(0xFF2E7D32)
                                  : AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
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

class _WinnerBanner extends StatelessWidget {
  final Plant left;
  final Plant right;
  final List<_RowData> rows;

  const _WinnerBanner(
      {required this.left, required this.right, required this.rows});

  @override
  Widget build(BuildContext context) {
    final leftScore = rows.where((r) => r.leftWins).length;
    final rightScore = rows.where((r) => r.rightWins).length;

    String emoji;
    String title;
    String subtitle;

    if (leftScore > rightScore) {
      emoji = '🏆';
      title = '${left.nameTh} ชนะ!';
      subtitle = 'ดีกว่าใน $leftScore หัวข้อ';
    } else if (rightScore > leftScore) {
      emoji = '🏆';
      title = '${right.nameTh} ชนะ!';
      subtitle = 'ดีกว่าใน $rightScore หัวข้อ';
    } else {
      emoji = '🤝';
      title = 'เสมอกัน!';
      subtitle = 'ทั้งสองต้นไม้มีข้อดีพอๆ กัน';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.primary.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.notoSansThai(
              fontSize: 13,
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ScorePill(name: left.nameTh, score: leftScore),
              const SizedBox(width: 12),
              Text('vs', style: GoogleFonts.outfit(color: AppColors.outline)),
              const SizedBox(width: 12),
              _ScorePill(name: right.nameTh, score: rightScore),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String name;
  final int score;
  const _ScorePill({required this.name, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            '$score ⭐',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(
            name,
            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}
