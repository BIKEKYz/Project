import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../data/plant_repository.dart';
import '../../models/plant.dart';

// ─────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────

enum RoomDirection {
  north,
  south,
  east,
  west,
  northeast,
  northwest,
  southeast,
  southwest
}

extension RoomDirectionExt on RoomDirection {
  String label(String lang) {
    const th = {
      RoomDirection.north: 'เหนือ',
      RoomDirection.south: 'ใต้',
      RoomDirection.east: 'ตะวันออก',
      RoomDirection.west: 'ตะวันตก',
      RoomDirection.northeast: 'ตะวันออกเฉียงเหนือ',
      RoomDirection.northwest: 'ตะวันตกเฉียงเหนือ',
      RoomDirection.southeast: 'ตะวันออกเฉียงใต้',
      RoomDirection.southwest: 'ตะวันตกเฉียงใต้',
    };
    const en = {
      RoomDirection.north: 'North',
      RoomDirection.south: 'South',
      RoomDirection.east: 'East',
      RoomDirection.west: 'West',
      RoomDirection.northeast: 'Northeast',
      RoomDirection.northwest: 'Northwest',
      RoomDirection.southeast: 'Southeast',
      RoomDirection.southwest: 'Southwest',
    };
    return (lang == 'en' ? en : th)[this]!;
  }

  String get shortLabel {
    const map = {
      RoomDirection.north: 'N',
      RoomDirection.south: 'S',
      RoomDirection.east: 'E',
      RoomDirection.west: 'W',
      RoomDirection.northeast: 'NE',
      RoomDirection.northwest: 'NW',
      RoomDirection.southeast: 'SE',
      RoomDirection.southwest: 'SW',
    };
    return map[this]!;
  }

  double get angle {
    const map = {
      RoomDirection.north: 0.0,
      RoomDirection.northeast: 45.0,
      RoomDirection.east: 90.0,
      RoomDirection.southeast: 135.0,
      RoomDirection.south: 180.0,
      RoomDirection.southwest: 225.0,
      RoomDirection.west: 270.0,
      RoomDirection.northwest: 315.0,
    };
    return map[this]! * pi / 180;
  }
}

class _QuizQuestion {
  final String questionTh;
  final String questionEn;
  final List<String> optionsTh;
  final List<String> optionsEn;
  final List<int> scores; // light score per option (0=dark, 3=bright)

  const _QuizQuestion({
    required this.questionTh,
    required this.questionEn,
    required this.optionsTh,
    required this.optionsEn,
    required this.scores,
  });
}

const _questions = [
  _QuizQuestion(
    questionTh: 'แสงแดดเข้าห้องช่วงเวลาไหน?',
    questionEn: 'When does sunlight enter the room?',
    optionsTh: [
      'ทั้งวัน (6+ ชม.)',
      'ช่วงเช้า/บ่าย (3–6 ชม.)',
      'น้อยกว่า 3 ชม.',
      'แทบไม่มีแสง'
    ],
    optionsEn: [
      'All day (6+ hrs)',
      'Morning/Afternoon (3–6 hrs)',
      'Less than 3 hrs',
      'Almost no light'
    ],
    scores: [3, 2, 1, 0],
  ),
  _QuizQuestion(
    questionTh: 'มีม่านกรองแสงหรือไม่?',
    questionEn: 'Do you have curtains or blinds?',
    optionsTh: [
      'ไม่มีม่าน',
      'ม่านบาง (กรองบางส่วน)',
      'ม่านหนา (กรองมาก)',
      'ม่านทึบ'
    ],
    optionsEn: [
      'No curtains',
      'Sheer curtains (partial filter)',
      'Thick curtains (heavy filter)',
      'Blackout curtains'
    ],
    scores: [3, 2, 1, 0],
  ),
  _QuizQuestion(
    questionTh: 'มีสิ่งกีดขวางแสงภายนอก?',
    questionEn: 'Are there obstructions outside?',
    optionsTh: [
      'ไม่มี (วิวโล่ง)',
      'ต้นไม้/รั้ว',
      'ตึกสูง (บังบางส่วน)',
      'ตึกสูงบังทั้งหมด'
    ],
    optionsEn: [
      'None (open view)',
      'Trees/fence',
      'Tall building (partial)',
      'Tall building (full block)'
    ],
    scores: [3, 2, 1, 0],
  ),
  _QuizQuestion(
    questionTh: 'วางต้นไม้ห่างจากหน้าต่างกี่เมตร?',
    questionEn: 'How far from the window will you place the plant?',
    optionsTh: [
      'ชิดหน้าต่าง (< 0.5 ม.)',
      '0.5–1 เมตร',
      '1–2 เมตร',
      'มากกว่า 2 เมตร'
    ],
    optionsEn: [
      'Right at window (< 0.5m)',
      '0.5–1 meter',
      '1–2 meters',
      'More than 2 meters'
    ],
    scores: [3, 2, 1, 0],
  ),
];

// ─────────────────────────────────────────────
// Result model
// ─────────────────────────────────────────────

class _LightResult {
  final String levelTh;
  final String levelEn;
  final String descTh;
  final String descEn;
  final String emoji;
  final Color color;
  final List<String> plantsTh;
  final List<String> plantsEn;

  /// Plant IDs from PlantRepository (parallel to plantsEn, null = not in repo)
  final List<String?> plantIds;
  final String tipTh;
  final String tipEn;

  const _LightResult({
    required this.levelTh,
    required this.levelEn,
    required this.descTh,
    required this.descEn,
    required this.emoji,
    required this.color,
    required this.plantsTh,
    required this.plantsEn,
    required this.plantIds,
    required this.tipTh,
    required this.tipEn,
  });
}

_LightResult _getResult(int score) {
  if (score >= 10) {
    return const _LightResult(
      levelTh: 'แสงจ้า',
      levelEn: 'Bright Direct Light',
      descTh: 'ห้องของคุณได้รับแสงแดดโดยตรงมาก เหมาะกับต้นไม้ที่ชอบแสงแรง',
      descEn:
          'Your room gets strong direct sunlight — perfect for sun-loving plants.',
      emoji: '☀️',
      color: Color(0xFFFF9800),
      plantsTh: [
        'กระบองเพชร',
        'อโลเวร่า',
        'ซักคิวเลนต์',
        'โหระพา',
        'มะเขือเทศ'
      ],
      plantsEn: ['Cactus', 'Aloe Vera', 'Succulents', 'Basil', 'Tomato'],
      plantIds: ['cactus', 'aloe_vera', null, null, null],
      tipTh: 'ระวังใบไหม้ — หมุนกระถางทุก 2 สัปดาห์เพื่อให้แสงสม่ำเสมอ',
      tipEn: 'Watch for leaf burn — rotate pot every 2 weeks for even light.',
    );
  } else if (score >= 7) {
    return const _LightResult(
      levelTh: 'แสงสว่างทางอ้อม',
      levelEn: 'Bright Indirect Light',
      descTh: 'แสงดี แต่ไม่ถึงกับแดดจ้า เหมาะกับต้นไม้ส่วนใหญ่',
      descEn:
          'Good light but not harsh — most popular houseplants thrive here.',
      emoji: '🌤',
      color: Color(0xFF4CAF50),
      plantsTh: ['มอนสเตอร่า', 'ยางอินเดีย', 'โกสน', 'เฟิร์น', 'พลูด่าง'],
      plantsEn: ['Monstera', 'Rubber Plant', 'Croton', 'Boston Fern', 'Pothos'],
      plantIds: ['monstera', 'rubber_plant', null, 'boston_fern', 'pothos'],
      tipTh: 'ตำแหน่งนี้เหมาะที่สุด! วางห่างหน้าต่าง 0.5–1 เมตรเพื่อผลดีที่สุด',
      tipEn: 'Ideal spot! Place 0.5–1m from window for best results.',
    );
  } else if (score >= 4) {
    return const _LightResult(
      levelTh: 'แสงน้อย',
      levelEn: 'Low Light',
      descTh: 'แสงน้อย แต่ยังมีต้นไม้หลายชนิดที่เจริญเติบโตได้ดี',
      descEn: 'Low light, but several plants can still thrive here.',
      emoji: '🌥',
      color: Color(0xFF2196F3),
      plantsTh: [
        'เดหลี',
        'ลิ้นมังกร',
        'กวักมรกต',
        'ปาล์มอาเรก้า',
        'ฟิโลเดนดรอน'
      ],
      plantsEn: [
        'Peace Lily',
        'Snake Plant',
        'ZZ Plant',
        'Areca Palm',
        'Philodendron'
      ],
      plantIds: ['peace_lily', 'sansevieria', 'zz_plant', null, 'philodendron'],
      tipTh: 'เพิ่มแสงเทียม (grow light) เพื่อช่วยต้นไม้เติบโตดีขึ้น',
      tipEn: 'Add a grow light to help plants thrive better.',
    );
  } else {
    return const _LightResult(
      levelTh: 'มืดมาก',
      levelEn: 'Very Low / Dark',
      descTh: 'ห้องมืดมาก ต้นไม้ส่วนใหญ่จะไม่รอด แนะนำให้ใช้ grow light',
      descEn: 'Very dark room — most plants won\'t survive. Use a grow light.',
      emoji: '🌑',
      color: Color(0xFF607D8B),
      plantsTh: ['ลิ้นมังกร', 'กวักมรกต', 'ต้นไม้ประดิษฐ์ 😅'],
      plantsEn: ['Snake Plant', 'ZZ Plant', 'Artificial Plants 😅'],
      plantIds: ['sansevieria', 'zz_plant', null],
      tipTh: 'ใช้หลอด LED grow light 12–16 ชม./วัน เพื่อทดแทนแสงธรรมชาติ',
      tipEn: 'Use LED grow light 12–16 hrs/day to replace natural light.',
    );
  }
}

// ─────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────

class LightAdvisorScreen extends StatefulWidget {
  final String lang;
  const LightAdvisorScreen({super.key, this.lang = 'th'});

  @override
  State<LightAdvisorScreen> createState() => _LightAdvisorScreenState();
}

class _LightAdvisorScreenState extends State<LightAdvisorScreen>
    with SingleTickerProviderStateMixin {
  // Step: 0 = room setup, 1..N = quiz, N+1 = result
  int _step = 0;
  RoomDirection _direction = RoomDirection.south;
  Offset _windowPos = const Offset(0.5, 0.0); // relative 0..1 on room walls
  final List<int?> _answers = List.filled(_questions.length, null);
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  bool get _isTh => widget.lang != 'en';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    _animCtrl.reverse().then((_) {
      setState(() => _step++);
      _animCtrl.forward();
    });
  }

  void _prevStep() {
    _animCtrl.reverse().then((_) {
      setState(() => _step--);
      _animCtrl.forward();
    });
  }

  void _reset() {
    _animCtrl.reverse().then((_) {
      setState(() {
        _step = 0;
        _answers.fillRange(0, _answers.length, null);
        _direction = RoomDirection.south;
        _windowPos = const Offset(0.5, 0.0);
      });
      _animCtrl.forward();
    });
  }

  int get _totalScore {
    int s = 0;
    for (int i = 0; i < _questions.length; i++) {
      final a = _answers[i];
      if (a != null) s += _questions[i].scores[a];
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F5),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    if (_step == 0) return _buildRoomSetup();
    final quizIndex = _step - 1;
    if (quizIndex < _questions.length) return _buildQuiz(quizIndex);
    return _buildResult();
  }

  // ── Step 0: Room Setup ──────────────────────────────────────

  Widget _buildRoomSetup() {
    final info = _DirectionInfoCard.directionData(_direction, _isTh);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.wb_sunny_outlined,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isTh ? 'ประเมินแสงในห้อง' : 'Room Light Advisor',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      _isTh
                          ? 'เลือกทิศและตำแหน่งหน้าต่าง'
                          : 'Choose direction & window position',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 13, color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Room map
          Text(
            _isTh ? 'ตำแหน่งหน้าต่าง' : 'Window Position',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          _RoomLayoutWidget(
            windowPos: _windowPos,
            direction: _direction,
            lang: widget.lang,
            onWindowMoved: (pos) => setState(() => _windowPos = pos),
          ),
          const SizedBox(height: 24),

          // Direction grid
          Text(
            _isTh ? 'ทิศที่หน้าต่างหันไป' : 'Window Facing Direction',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          _CompassPicker(
            selected: _direction,
            lang: widget.lang,
            onSelected: (d) => setState(() => _direction = d),
          ),
          const SizedBox(height: 16),

          // Direction summary pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: info.$3.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: info.$3.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Text(info.$1, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isTh
                            ? 'ทิศ${_direction.label(widget.lang)}'
                            : '${_direction.label(widget.lang)} Facing',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: info.$3,
                        ),
                      ),
                      Text(
                        info.$2,
                        style: GoogleFonts.notoSansThai(
                            fontSize: 12, color: Colors.black54, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isTh ? 'ถัดไป' : 'Next',
                    style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quiz Steps ──────────────────────────────────────────────

  Widget _buildQuiz(int index) {
    final q = _questions[index];
    final question = _isTh ? q.questionTh : q.questionEn;
    final options = _isTh ? q.optionsTh : q.optionsEn;
    final selected = _answers[index];
    final isLast = index == _questions.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar row
          Row(
            children: [
              GestureDetector(
                onTap: _prevStep,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      size: 16, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isTh ? 'คำถามที่' : 'Question',
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: Colors.black38),
                        ),
                        Text(
                          '${index + 1} / ${_questions.length}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (index + 1) / _questions.length,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          Text(
            question,
            style: GoogleFonts.notoSansThai(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A2820),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          ...List.generate(options.length, (i) {
            final isSelected = selected == i;
            return GestureDetector(
              onTap: () => setState(() => _answers[index] = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.black.withOpacity(0.08),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Colors.white.withOpacity(0.25)
                            : AppColors.primary.withOpacity(0.07),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + i),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                isSelected ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        options[i],
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14,
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 18),
                  ],
                ),
              ),
            );
          }),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selected != null ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.black.withOpacity(0.08),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                isLast
                    ? (_isTh ? 'ดูผลลัพธ์' : 'See Results')
                    : (_isTh ? 'ถัดไป' : 'Next'),
                style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Result ──────────────────────────────────────────────────

  Widget _buildResult() {
    final result = _getResult(_totalScore);
    final plants = _isTh ? result.plantsTh : result.plantsEn;
    final tip = _isTh ? result.tipTh : result.tipEn;
    final allPlants = PlantRepository.all();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero result card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: result.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: result.color.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(result.emoji, style: const TextStyle(fontSize: 52)),
                const SizedBox(height: 10),
                Text(
                  _isTh ? result.levelTh : result.levelEn,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: result.color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isTh ? result.descTh : result.descEn,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansThai(
                      fontSize: 13, color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 16),
                // Score bar inside card
                Row(
                  children: [
                    Text(
                      _isTh ? 'คะแนนแสง' : 'Light Score',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: Colors.black45),
                    ),
                    const Spacer(),
                    Text(
                      '$_totalScore / 12',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: result.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _totalScore / 12,
                    backgroundColor: result.color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(result.color),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Room info chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.07)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🧭', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  _isTh
                      ? 'หน้าต่างหันทิศ${_direction.label(widget.lang)}'
                      : '${_direction.label(widget.lang)}-facing window',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Plant recommendations
          Text(
            _isTh ? 'ต้นไม้ที่เหมาะกับห้องคุณ' : 'Plants for Your Room',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A2820),
            ),
          ),
          Text(
            _isTh
                ? 'กดที่ชื่อต้นไม้เพื่อดูรายละเอียด'
                : 'Tap a plant name for details',
            style:
                GoogleFonts.notoSansThai(fontSize: 12, color: Colors.black38),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(plants.length, (i) {
              final plantId =
                  i < result.plantIds.length ? result.plantIds[i] : null;
              final plant = plantId != null
                  ? allPlants.where((p) => p.id == plantId).firstOrNull
                  : null;
              final hasData = plant != null;
              return GestureDetector(
                onTap: hasData
                    ? () => _showPlantPopup(context, plant, result.color)
                    : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasData
                        ? result.color.withOpacity(0.1)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasData
                          ? result.color.withOpacity(0.5)
                          : Colors.black.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        plants[i],
                        style: GoogleFonts.notoSansThai(
                          fontSize: 13,
                          color: hasData ? result.color : Colors.black54,
                          fontWeight:
                              hasData ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (hasData) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded,
                            size: 14, color: result.color),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Tip card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('💡', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isTh ? 'เคล็ดลับ' : 'Pro Tip',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tip,
                        style: GoogleFonts.notoSansThai(
                            fontSize: 13, height: 1.5, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Reset button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                _isTh ? 'ประเมินใหม่' : 'Start Over',
                style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Plant Info Popup ─────────────────────────────────────────

  void _showPlantPopup(BuildContext context, Plant plant, Color accentColor) {
    final isTh = _isTh;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF7F9F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image + name header
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              plant.image,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(Icons.eco_rounded,
                                    size: 40, color: accentColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isTh ? plant.nameTh : plant.nameEn,
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  plant.scientific,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black38,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _MiniTag(
                                      label: _lightLabel(plant.light, isTh),
                                      icon: Icons.wb_sunny_outlined,
                                      color: accentColor,
                                    ),
                                    const SizedBox(width: 6),
                                    _MiniTag(
                                      label: _diffLabel(plant.difficulty, isTh),
                                      icon: Icons.bar_chart_rounded,
                                      color: AppColors.secondary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description
                      Text(
                        plant.description,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quick facts grid
                      _FactsGrid(plant: plant, isTh: isTh),
                      const SizedBox(height: 20),

                      // Leaf warnings
                      ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color:
                                    const Color(0xFFFFCC02).withOpacity(0.4)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('🍃', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isTh
                                          ? 'สัญญาณเตือนจากใบ'
                                          : 'Leaf Warnings',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF795548),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      plant.leafWarnings,
                                      style: GoogleFonts.notoSansThai(
                                        fontSize: 12,
                                        height: 1.5,
                                        color: const Color(0xFF795548),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  String _lightLabel(Light light, bool isTh) {
    switch (light) {
      case Light.low:
        return isTh ? 'แสงน้อย' : 'Low Light';
      case Light.medium:
        return isTh ? 'แสงปานกลาง' : 'Medium Light';
      case Light.bright:
        return isTh ? 'แสงสว่าง' : 'Bright Light';
    }
  }

  String _diffLabel(Difficulty diff, bool isTh) {
    switch (diff) {
      case Difficulty.easy:
        return isTh ? 'ง่าย' : 'Easy';
      case Difficulty.medium:
        return isTh ? 'ปานกลาง' : 'Medium';
      case Difficulty.hard:
        return isTh ? 'ยาก' : 'Hard';
    }
  }
}

// ─────────────────────────────────────────────
// Mini Tag Widget (for popup header)
// ─────────────────────────────────────────────

class _MiniTag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _MiniTag({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Facts Grid Widget (for popup body)
// ─────────────────────────────────────────────

class _FactsGrid extends StatelessWidget {
  final Plant plant;
  final bool isTh;

  const _FactsGrid({required this.plant, required this.isTh});

  @override
  Widget build(BuildContext context) {
    final facts = [
      (
        Icons.thermostat_outlined,
        isTh ? 'อุณหภูมิ' : 'Temp',
        plant.temperature
      ),
      (
        Icons.water_drop_outlined,
        isTh ? 'รดน้ำทุก' : 'Water every',
        '${plant.waterIntervalDays} ${isTh ? 'วัน' : 'days'}'
      ),
      (Icons.opacity_outlined, isTh ? 'ความชื้น' : 'Humidity', plant.humidity),
      (Icons.grass_outlined, isTh ? 'ดิน' : 'Soil', plant.soil),
      (
        Icons.pets_outlined,
        isTh ? 'ปลอดภัยสัตว์' : 'Pet Safe',
        plant.petSafe ? (isTh ? '✅ ใช่' : '✅ Yes') : (isTh ? '❌ ไม่' : '❌ No')
      ),
      (
        Icons.air_outlined,
        isTh ? 'ฟอกอากาศ' : 'Air Purify',
        plant.airPurifying
            ? (isTh ? '✅ ใช่' : '✅ Yes')
            : (isTh ? '❌ ไม่' : '❌ No')
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: facts.map((f) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Icon(f.$1, size: 16, color: AppColors.primary.withOpacity(0.6)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      f.$2,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: Colors.black38,
                      ),
                    ),
                    Text(
                      f.$3,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
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
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────
// 2D Room Layout Widget
// ─────────────────────────────────────────────

class _RoomLayoutWidget extends StatefulWidget {
  final Offset windowPos;
  final RoomDirection direction;
  final String lang;
  final ValueChanged<Offset> onWindowMoved;

  const _RoomLayoutWidget({
    required this.windowPos,
    required this.direction,
    required this.lang,
    required this.onWindowMoved,
  });

  @override
  State<_RoomLayoutWidget> createState() => _RoomLayoutWidgetState();
}

class _RoomLayoutWidgetState extends State<_RoomLayoutWidget> {
  // windowPos: 0..1 along the top wall (for simplicity, window is on top wall)
  // We'll let user drag along top wall only (facing direction)

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return GestureDetector(
              onPanUpdate: (details) {
                // Snap window to nearest wall
                final localPos = details.localPosition;
                final relX = (localPos.dx / w).clamp(0.1, 0.9);
                final relY = (localPos.dy / h).clamp(0.1, 0.9);

                // Find nearest wall
                final distTop = relY;
                final distBottom = 1 - relY;
                final distLeft = relX;
                final distRight = 1 - relX;
                final minDist =
                    [distTop, distBottom, distLeft, distRight].reduce(min);

                Offset newPos;
                if (minDist == distTop) {
                  newPos = Offset(relX, 0.0);
                } else if (minDist == distBottom) {
                  newPos = Offset(relX, 1.0);
                } else if (minDist == distLeft) {
                  newPos = Offset(0.0, relY);
                } else {
                  newPos = Offset(1.0, relY);
                }
                widget.onWindowMoved(newPos);
              },
              child: CustomPaint(
                painter: _RoomPainter(
                  windowPos: widget.windowPos,
                  direction: widget.direction,
                  lang: widget.lang,
                ),
                size: Size(w, h),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoomPainter extends CustomPainter {
  final Offset windowPos;
  final RoomDirection direction;
  final String lang;

  _RoomPainter({
    required this.windowPos,
    required this.direction,
    required this.lang,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final padding = 24.0;

    // Room floor
    final roomRect = Rect.fromLTRB(padding, padding, w - padding, h - padding);
    final roomPaint = Paint()
      ..color = const Color(0xFFF0F4EE)
      ..style = PaintingStyle.fill;
    final roomBorderPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(
        RRect.fromRectAndRadius(roomRect, const Radius.circular(12)),
        roomPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(roomRect, const Radius.circular(12)),
        roomBorderPaint);

    // Direction label on walls
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    void drawWallLabel(String text, Offset pos) {
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          color: AppColors.primary.withOpacity(0.4),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    drawWallLabel(direction.shortLabel, Offset(w / 2, padding / 2));
    drawWallLabel(
        _opposite(direction.shortLabel), Offset(w / 2, h - padding / 2));
    drawWallLabel(_leftOf(direction.shortLabel), Offset(padding / 2, h / 2));
    drawWallLabel(
        _rightOf(direction.shortLabel), Offset(w - padding / 2, h / 2));

    // Compute window pixel position
    final winPx = _wallToPixel(windowPos, roomRect);

    // Sun ray direction based on window position
    final isTopWall = windowPos.dy < 0.1;
    final isBottomWall = windowPos.dy > 0.9;
    final isLeftWall = windowPos.dx < 0.1;
    // final isRightWall = windowPos.dx > 0.9;

    Offset rayDir;
    if (isTopWall) {
      rayDir = const Offset(0, 1);
    } else if (isBottomWall) {
      rayDir = const Offset(0, -1);
    } else if (isLeftWall) {
      rayDir = const Offset(1, 0);
    } else {
      rayDir = const Offset(-1, 0);
    }

    // Draw light cone
    final lightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFEB3B).withOpacity(0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
          center: winPx + rayDir * 60, width: 120, height: 120));
    canvas.drawCircle(winPx + rayDir * 60, 70, lightPaint);

    // Draw window
    final winPaint = Paint()
      ..color = const Color(0xFF64B5F6)
      ..style = PaintingStyle.fill;
    final winBorderPaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final winSize = 28.0;
    Rect winRect;
    if (isTopWall || isBottomWall) {
      winRect = Rect.fromCenter(center: winPx, width: winSize, height: 8);
    } else {
      winRect = Rect.fromCenter(center: winPx, width: 8, height: winSize);
    }
    canvas.drawRect(winRect, winPaint);
    canvas.drawRect(winRect, winBorderPaint);

    // Window label
    textPainter.text = TextSpan(
      text: lang == 'en' ? 'Window' : 'หน้าต่าง',
      style: const TextStyle(
        color: Color(0xFF1565C0),
        fontSize: 9,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        winPx +
            Offset(
                -textPainter.width / 2,
                isTopWall
                    ? 8
                    : isBottomWall
                        ? -18
                        : 10));

    // Plant icon (center of room)
    final plantCenter = Offset(w / 2, h / 2);
    final plantPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(plantCenter, 18, plantPaint);
    textPainter.text =
        const TextSpan(text: '🪴', style: TextStyle(fontSize: 22));
    textPainter.layout();
    textPainter.paint(canvas,
        plantCenter - Offset(textPainter.width / 2, textPainter.height / 2));

    // Drag hint
    textPainter.text = TextSpan(
      text: lang == 'en' ? 'Drag window to wall' : 'ลากหน้าต่างไปที่ผนัง',
      style: TextStyle(
        color: AppColors.outline.withOpacity(0.6),
        fontSize: 10,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((w - textPainter.width) / 2, h - 14));
  }

  Offset _wallToPixel(Offset rel, Rect room) {
    if (rel.dy < 0.1) {
      // top wall
      return Offset(room.left + rel.dx * room.width, room.top);
    } else if (rel.dy > 0.9) {
      // bottom wall
      return Offset(room.left + rel.dx * room.width, room.bottom);
    } else if (rel.dx < 0.1) {
      // left wall
      return Offset(room.left, room.top + rel.dy * room.height);
    } else {
      // right wall
      return Offset(room.right, room.top + rel.dy * room.height);
    }
  }

  String _opposite(String d) {
    const map = {
      'N': 'S',
      'S': 'N',
      'E': 'W',
      'W': 'E',
      'NE': 'SW',
      'NW': 'SE',
      'SE': 'NW',
      'SW': 'NE',
    };
    return map[d] ?? '';
  }

  String _leftOf(String d) {
    const map = {
      'N': 'W',
      'S': 'E',
      'E': 'N',
      'W': 'S',
      'NE': 'NW',
      'NW': 'SW',
      'SE': 'NE',
      'SW': 'SE',
    };
    return map[d] ?? '';
  }

  String _rightOf(String d) {
    const map = {
      'N': 'E',
      'S': 'W',
      'E': 'S',
      'W': 'N',
      'NE': 'SE',
      'NW': 'NE',
      'SE': 'SW',
      'SW': 'NW',
    };
    return map[d] ?? '';
  }

  @override
  bool shouldRepaint(_RoomPainter old) =>
      old.windowPos != windowPos || old.direction != direction;
}

// ─────────────────────────────────────────────
// Compass Picker
// ─────────────────────────────────────────────

class _CompassPicker extends StatelessWidget {
  final RoomDirection selected;
  final String lang;
  final ValueChanged<RoomDirection> onSelected;

  const _CompassPicker({
    required this.selected,
    required this.lang,
    required this.onSelected,
  });

  // 3×3 grid layout order (null = center spacer)
  static const _grid = [
    RoomDirection.northwest,
    RoomDirection.north,
    RoomDirection.northeast,
    RoomDirection.west,
    null,
    RoomDirection.east,
    RoomDirection.southwest,
    RoomDirection.south,
    RoomDirection.southeast,
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 1.8,
      children: _grid.map((dir) {
        if (dir == null) {
          // center: compass emoji
          return Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('🧭', style: TextStyle(fontSize: 20)),
            ),
          );
        }
        final isSelected = dir == selected;
        return GestureDetector(
          onTap: () => onSelected(dir),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : Colors.black.withOpacity(0.08),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                dir.shortLabel,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────
// Direction Info Card
// ─────────────────────────────────────────────

class _DirectionInfoCard extends StatelessWidget {
  final RoomDirection direction;
  final String lang;

  const _DirectionInfoCard({required this.direction, required this.lang});

  /// Static accessor so _buildRoomSetup can call without an instance
  static (String, String, Color) directionData(RoomDirection d, bool isTh) =>
      _directionInfoStatic(d, isTh);

  @override
  Widget build(BuildContext context) {
    final isTh = lang != 'en';
    final info = _directionInfoStatic(direction, isTh);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: info.$3.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: info.$3.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(info.$1, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTh
                      ? 'ทิศ${direction.label(lang)}'
                      : '${direction.label(lang)} Facing',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: info.$3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.$2,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
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

// Top-level helper shared by _DirectionInfoCard and _buildRoomSetup
(String, String, Color) _directionInfoStatic(RoomDirection d, bool isTh) {
  switch (d) {
    case RoomDirection.south:
      return (
        '☀️',
        isTh
            ? 'แสงแดดตลอดวัน เหมาะกับต้นไม้ที่ชอบแสงแรง'
            : 'Full sun all day — great for sun-loving plants',
        const Color(0xFFFF9800),
      );
    case RoomDirection.north:
      return (
        '🌥',
        isTh
            ? 'แสงน้อย เหมาะกับต้นไม้ทนร่ม'
            : 'Low light — best for shade-tolerant plants',
        const Color(0xFF607D8B),
      );
    case RoomDirection.east:
      return (
        '🌅',
        isTh
            ? 'แสงอ่อนช่วงเช้า เหมาะกับต้นไม้ส่วนใหญ่'
            : 'Gentle morning sun — great for most houseplants',
        const Color(0xFF4CAF50),
      );
    case RoomDirection.west:
      return (
        '🌇',
        isTh
            ? 'แสงแรงช่วงบ่าย ระวังใบไหม้'
            : 'Intense afternoon sun — watch for leaf burn',
        const Color(0xFFFF5722),
      );
    default:
      return (
        '🌤',
        isTh
            ? 'แสงปานกลาง เหมาะกับต้นไม้หลายชนิด'
            : 'Moderate light — suitable for many plants',
        const Color(0xFF2196F3),
      );
  }
}
