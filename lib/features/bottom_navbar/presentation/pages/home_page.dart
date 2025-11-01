import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_steps_tracker/core/data/services/firestore_services.dart';
import 'package:flutter_steps_tracker/utilities/constants/api_path.dart';
import 'week_steps_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _kBaselineKey = 'today_baseline';
  static const _kDateKey = 'today_date';
  static const _kDailyGoal = 8000;

  StreamSubscription<StepCount>? _sub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  SharedPreferences? _prefs;

  int _deviceSteps = 0;
  int _todaySteps = 0;
  int _todayPoints = 0;

  int _streak = 0;

  int _userHealthPoints = 0;
  int _userTotalSteps = 0;
  int _userTotalCalories = 0;
  String _userName = 'Guest';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await _ensurePermission();

    final user = FirebaseAuth.instance.currentUser ??
        (await FirebaseAuth.instance.signInAnonymously()).user!;
    final uid = user.uid;

    _prefs = await SharedPreferences.getInstance();
    _sub = Pedometer.stepCountStream
        .listen(_onStep, onError: (e) => debugPrint('step error: $e'));

    _userSub = FirebaseFirestore.instance
        .doc(APIPath.user(uid))
        .snapshots()
        .listen((snap) {
      final data = snap.data() ?? {};
      setState(() {
        _userHealthPoints = (data['healthPoints'] ?? 0) as int;
        _userTotalSteps = (data['totalSteps'] ?? 0) as int;
        _userTotalCalories = (data['totalCalories'] ?? 0) as int;
        _userName = (data['name'] ?? 'Guest') as String;
        _streak = (data['streak'] ?? _streak) as int;
      });
    });

    await _calcStreakA();
  }

  Future<void> _ensurePermission() async {
    if (!Platform.isAndroid) return;
    final st = await Permission.activityRecognition.status;
    if (st.isDenied || st.isRestricted) {
      await Permission.activityRecognition.request();
    }
  }

  Future<void> _onStep(StepCount s) async {
    _deviceSteps = s.steps;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = _prefs!.getString(_kDateKey);
    if (savedDate != today || !_prefs!.containsKey(_kBaselineKey)) {
      await _prefs!.setString(_kDateKey, today);
      await _prefs!.setInt(_kBaselineKey, _deviceSteps);
    }
    final base = _prefs!.getInt(_kBaselineKey) ?? _deviceSteps;
    _todaySteps = (_deviceSteps - base).clamp(0, 1 << 30);

    // ✅ 新的积分规则：每 100 步加 50 点
    // 100 -> 50, 199 -> 50, 200 -> 100
    _todayPoints = (_todaySteps ~/ 100) * 50;

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }

  Future<void> _calcStreakA() async {
    final user = FirebaseAuth.instance.currentUser ??
        (await FirebaseAuth.instance.signInAnonymously()).user!;
    final uid = user.uid;

    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 60; i++) {
      final d =
      DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final id = d.toIso8601String().substring(0, 10);

      final snap = await FirebaseFirestore.instance
          .doc(APIPath.setDailyStepsAndPoints(uid, id))
          .get();
      final data = snap.data() ?? const {};

      final steps = (data['steps'] ?? 0) as int;
      final settled = (data['settledSteps'] ?? 0) as int;
      final maxSteps = steps > settled ? steps : settled;

      if (maxSteps >= _kDailyGoal) {
        streak++;
      } else {
        break;
      }
    }

    if (mounted) {
      setState(() {
        _streak = streak;
      });
    }

    await FirebaseFirestore.instance
        .doc(APIPath.user(uid))
        .set({'streak': streak}, SetOptions(merge: true));
  }

  Future<void> _settlePoints() async {
    final user = FirebaseAuth.instance.currentUser ??
        (await FirebaseAuth.instance.signInAnonymously()).user!;
    final uid = user.uid;

    final todayId = DateTime.now().toIso8601String().substring(0, 10);
    final localSteps = _todaySteps;
    final localPoints = _todayPoints; // ✅ 已经是 100 步 = 50 点
    final localCalories = (_todaySteps * 0.04).floor();

    final todayRef =
    FirebaseFirestore.instance.doc(APIPath.setDailyStepsAndPoints(uid, todayId));
    final todaySnap = await todayRef.get();
    final todayData = todaySnap.data() ?? {};

    final settledSteps = (todayData['settledSteps'] ?? 0) as int;
    final settledPoints = (todayData['settledPoints'] ?? 0) as int;
    final settledCalories = (todayData['settledCalories'] ?? 0) as int;

    final deltaSteps = (localSteps - settledSteps).clamp(0, 1 << 30);
    final deltaPoints = (localPoints - settledPoints).clamp(0, 1 << 30);
    final deltaCalories = (localCalories - settledCalories).clamp(0, 1 << 30);

    if (deltaSteps == 0 && deltaPoints == 0 && deltaCalories == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Today is already settled.')),
        );
      }
      return;
    }

    final userRef = FirebaseFirestore.instance.doc(APIPath.user(uid));
    final userSnap = await userRef.get();
    final userData = userSnap.data() ?? {};
    final curSteps = (userData['totalSteps'] ?? 0) as int;
    final curHP = (userData['healthPoints'] ?? 0) as int;
    final curName = (userData['name'] ?? 'Guest') as String;
    final curTotalCalories = (userData['totalCalories'] ?? 0) as int;

    // 可能会让今天达标
    await _calcStreakA();

    await FirebaseFirestore.instance.doc(APIPath.user(uid)).set({
      'uid': uid,
      'name': curName,
      'totalSteps': curSteps + deltaSteps,
      'healthPoints': curHP + deltaPoints,
      'totalCalories': curTotalCalories + deltaCalories,
      'streak': _streak,
    }, SetOptions(merge: true));

    await FirestoreService.instance.setData(
      path: APIPath.setDailyStepsAndPoints(uid, todayId),
      data: {
        'id': todayId,
        'date': todayId,
        'steps': localSteps,
        'points': localPoints,
        'calories': localCalories,
        'settledSteps': localSteps,
        'settledPoints': localPoints,
        'settledCalories': localCalories,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Settled: +$deltaSteps steps (+$deltaPoints pts, +$deltaCalories kcal)',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_todaySteps / _kDailyGoal).clamp(0.0, 1.0);
    final km = (_todaySteps * 0.0008);
    final minutes = (_todaySteps / 110).floor();
    final calories = (_todaySteps * 0.04).floor();

    final now = DateTime.now();
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayStr =
        '${weekdayNames[(now.weekday - 1).clamp(0, 6)]} · ${now.month}/${now.day}';

    return Scaffold(
      backgroundColor: const Color(0xFF000612),
      body: Stack(
        children: [
          const _HexBg(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pedometer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Keep walking, $_userName 👟',
                              style: const TextStyle(
                                color: Color(0xCCDBEFFF),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Today • $todayStr',
                              style: const TextStyle(
                                color: Color(0x88D6E7FF),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _neonIconBtn(Icons.notifications_none_rounded),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _TopGlowCard(
                          title: 'Health Points',
                          value: '$_userHealthPoints',
                          icon: Icons.favorite_rounded,
                          chips: const [
                            _SmallChip('Total', Icons.calendar_today_rounded),
                            _SmallChip('Tracked', Icons.tag_faces_rounded),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TopGlowCard(
                          title: 'Today Steps',
                          value: '$_todaySteps',
                          icon: Icons.directions_walk_rounded,
                          chips: const [
                            _SmallChip('Daily', Icons.calendar_today_rounded),
                            _SmallChip('Later', Icons.schedule_rounded),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _GlassBlock(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _GlowRing(
                          progress: progress,
                          value: _todaySteps,
                          goal: _kDailyGoal,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D1FF).withOpacity(.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFF00D1FF).withOpacity(.6),
                            ),
                          ),
                          child: Text(
                            // ✅ 文案也自动跟着走
                            'Today you can get: $_todayPoints pts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double totalWidth = constraints.maxWidth;
                      final double itemWidth = (totalWidth - 10) / 2;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: itemWidth,
                            child: _StatCard(
                              title: 'Distance',
                              value: km.toStringAsFixed(2),
                              icon: Icons.map_outlined,
                              gradient: const [
                                Color(0x332BE0FF),
                                Color(0x1910C3FF),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _StatCard(
                              title: 'Active time',
                              value: '$minutes min',
                              icon: Icons.timer_outlined,
                              gradient: const [
                                Color(0x3320FFAE),
                                Color(0x1910C3FF),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _StatCard(
                              title: 'Today pts',
                              value: '$_todayPoints',
                              icon: Icons.stars_rounded,
                              gradient: const [
                                Color(0x33FF7BDA),
                                Color(0x1910C3FF),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _StatCard(
                              title: 'Calories',
                              value: '$calories kcal',
                              icon: Icons.local_fire_department_outlined,
                              gradient: const [
                                Color(0x33FFA860),
                                Color(0x1910C3FF),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  _GlassBlock(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const WeekStepsPage(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF9F43),
                                    Color(0xFFFF4E4E),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.local_fire_department_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Streak',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Current streak: $_streak day${_streak == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      color: Color(0xB3D6E7FF),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Builder(
                              builder: (_) {
                                final remain =
                                (_kDailyGoal - _todaySteps).clamp(0, _kDailyGoal);
                                final kept = remain == 0;
                                final text =
                                kept ? 'Kept today' : '$remain to keep';
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: LinearGradient(
                                      colors: kept
                                          ? const [
                                        Color(0xFF12D8FA),
                                        Color(0xFF4A5CFF),
                                      ]
                                          : const [
                                        Color(0xFF00E5FF),
                                        Color(0xFF2D6BFF),
                                      ],
                                    ),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(.18)),
                                  ),
                                  child: Text(
                                    text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _gradientIcon(Icons.north_east_rounded),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 58,
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF00E5FF),
                            Color(0xFF4A5CFF),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: _settlePoints,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          // ✅ 底部提示也改
                          "Settle today's points (100 steps = 50 pts)",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// --- 下面都是你的原来的 UI 组件，没改 ---
class _HexBg extends StatelessWidget {
  const _HexBg();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HexPainter(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF031020),
              Color(0xFF041B34),
              Color(0xFF061F43),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x101EC7FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const r = 30.0;
    final w = r * sqrt(3);

    for (double y = 20; y < size.height; y += r * 1.5) {
      for (double x = -40; x < size.width + 40; x += w) {
        final shift = ((y ~/ (r * 1.5)) % 2 == 0) ? 0.0 : w / 2;
        _drawHex(canvas, Offset(x + shift, y), r, paint);
      }
    }
  }

  void _drawHex(Canvas c, Offset center, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = pi / 3 * i;
      final pt = Offset(center.dx + r * cos(a), center.dy + r * sin(a));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget _neonIconBtn(IconData icon) {
  return Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: const Color(0xFF00E5FF).withOpacity(.7),
        width: 1.2,
      ),
      gradient: LinearGradient(
        colors: [
          const Color(0xFF00E5FF).withOpacity(.05),
          const Color(0xFF00E5FF).withOpacity(.01),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF00E5FF).withOpacity(.4),
          blurRadius: 12,
        ),
      ],
    ),
    child: Icon(icon, color: const Color(0xFF00E5FF), size: 20),
  );
}

class _TopGlowCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Widget> chips;
  const _TopGlowCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0x99161C4D),
            Color(0x6610195B),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(
          color: const Color(0xFF35E0FF),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4035E0FF),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFF7EB1), size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: chips,
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SmallChip(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2847),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: const Color(0xFF8CE2FF)),
          const SizedBox(width: 2),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFB3ECFF),
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowRing extends StatelessWidget {
  final double progress;
  final int value;
  final int goal;

  const _GlowRing({
    required this.progress,
    required this.value,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(230, 230),
            painter: _GlowRingPainter(progress),
          ),
          Positioned(
            top: 22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0x1A0BD7FF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x55D9F1FF)),
              ),
              child: const Text(
                'Today',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.directions_walk_rounded,
                color: Color(0xFF68D0FF),
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                value.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Goal: $goal',
                style: const TextStyle(
                  color: Color(0xCCCFDFFF),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlowRingPainter extends CustomPainter {
  final double p;
  _GlowRingPainter(this.p);

  @override
  void paint(Canvas canvas, Size size) {
    const ringStroke = 9.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - ringStroke) / 2;

    final outerPaint = Paint()
      ..color = const Color(0x2211D5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    canvas.drawCircle(center, radius - 2, outerPaint);

    final innerFill = Paint()..color = const Color(0xFF061827);
    canvas.drawCircle(center, radius - 10, innerFill);

    final ringRect = Rect.fromCircle(center: center, radius: radius);
    final ringPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [
          Color(0xFFF06BFF),
          Color(0xFF4DE7FF),
          Color(0xFF00D4FF),
          Color(0xFF65A6FF),
          Color(0xFFF06BFF),
        ],
      ).createShader(ringRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringStroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      ringRect,
      -pi / 2,
      max(0.015, p) * 2 * pi,
      false,
      ringPaint,
    );

    final tickPaint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    final tickPaintMajor = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const tickCount = 120;
    for (int i = 0; i < tickCount; i++) {
      final ang = -pi / 2 + 2 * pi * (i / tickCount);
      final isMajor = i % 10 == 0;

      final outer = Offset(
        center.dx + cos(ang) * (radius - 1.5),
        center.dy + sin(ang) * (radius - 1.5),
      );
      final inner = Offset(
        center.dx + cos(ang) * (radius - (isMajor ? 11 : 7)),
        center.dy + sin(ang) * (radius - (isMajor ? 11 : 7)),
      );
      canvas.drawLine(
        outer,
        inner,
        isMajor ? tickPaintMajor : tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GlowRingPainter oldDelegate) =>
      oldDelegate.p != p;
}

class _GlassBlock extends StatelessWidget {
  final Widget child;
  const _GlassBlock({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x1A0B2742),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF4FE6FF).withOpacity(.15),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color>? gradient;
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: gradient ??
              const [
                Color(0x101283FF),
                Color(0x1010C3FF),
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF4FE6FF).withOpacity(.16),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x33FFFFFF),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: const Color(0xFF8FE7FF),
                  shadows: [
                    Shadow(
                      color: const Color(0xFF00E5FF).withOpacity(.7),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xB3E1F4FF),
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 26,
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0x004FE6FF)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _gradientIcon(IconData icon, {double size = 22}) {
  return ShaderMask(
    shaderCallback: (r) => const LinearGradient(
      colors: [Color(0xFF00E5FF), Color(0xFF5C60FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(r),
    child: Icon(icon, color: Colors.white, size: size),
  );
}
