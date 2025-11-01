import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_steps_tracker/utilities/constants/api_path.dart';

class WeekStepsPage extends StatefulWidget {
  const WeekStepsPage({super.key});

  @override
  State<WeekStepsPage> createState() => _WeekStepsPageState();
}

class _WeekStepsPageState extends State<WeekStepsPage> {
  static const _kDailyGoal = 8000;

  bool _loading = true;

  // 上面打卡格子：最近 28 天（4 周）
  List<_DayData> _last28 = [];

  // history 用：最近 30 天（只展示 7 天）
  List<_DayData> _last30 = [];

  String _userName = 'Guest';
  int _currentStreak = 0;
  int _bestStreak30 = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser
        ?? (await FirebaseAuth.instance.signInAnonymously()).user!;
    final uid = user.uid;
    final now = DateTime.now();

    // 1) 拉用户
    final userFuture =
    FirebaseFirestore.instance.doc(APIPath.user(uid)).get();

    // 2) 拉 30 天的 daily
    final List<Future<DocumentSnapshot<Map<String, dynamic>>>> dailyFutures = [];
    final List<DateTime> dates = [];
    for (int i = 0; i < 30; i++) {
      final d = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final id = d.toIso8601String().substring(0, 10);
      dates.add(d);
      dailyFutures.add(
        FirebaseFirestore.instance
            .doc(APIPath.setDailyStepsAndPoints(uid, id))
            .get(),
      );
    }

    final userSnap = await userFuture;
    final dailySnaps = await Future.wait(dailyFutures);

    final userData = userSnap.data() ?? {};
    final name = (userData['name'] ?? 'Guest') as String;

    int currentRun = 0;
    int bestRun = 0;

    final List<_DayData> tmp28 = [];
    final List<_DayData> tmp30 = [];

    for (int i = 0; i < dailySnaps.length; i++) {
      final snap = dailySnaps[i];
      final d = dates[i];
      final id = d.toIso8601String().substring(0, 10);
      final data = snap.data();

      int steps = 0;
      int points = 0;
      if (data != null) {
        final s1 = (data['steps'] ?? 0) as int;
        final s2 = (data['settledSteps'] ?? 0) as int;
        steps = s1 > s2 ? s1 : s2;
        points = (data['points'] ?? data['settledPoints'] ?? 0) as int;
      }

      final met = steps >= _kDailyGoal;

      // 连续：从今天往回，到第一个没达标为止
      if (met) {
        currentRun++;
      } else {
        currentRun = 0;
      }
      bestRun = math.max(bestRun, currentRun);

      final dayData = _DayData(
        date: d,
        id: id,
        steps: steps,
        points: points,
        met: met,
      );

      if (i < 28) {
        tmp28.add(dayData);
      }
      tmp30.add(dayData);
    }

    // 28 天显示要从旧到新（左到右，上到下）
    tmp28.sort((a, b) => a.date.compareTo(b.date));
    // history 最新在上
    tmp30.sort((a, b) => b.date.compareTo(a.date));

    // merge 回 user
    await FirebaseFirestore.instance
        .doc(APIPath.user(uid))
        .set(
      {
        'streak': currentRun,
        'bestStreak30': bestRun,
      },
      SetOptions(merge: true),
    );

    if (!mounted) return;
    setState(() {
      _userName = name;
      _last28 = tmp28;
      _last30 = tmp30;
      _currentStreak = currentRun;
      _bestStreak30 = bestRun;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000612),
      body: Stack(
        children: [
          const _HexBg(),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // top bar
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0x55D4EEFF),
                            ),
                            color: const Color(0x1400E5FF),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Streak',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // header card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xCC12274C),
                          Color(0x8011223C),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: const Color(0xFF35E0FF),
                        width: 1.1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4035E0FF),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFAC6B),
                                Color(0xFFFF5F6B),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hey, $_userName',
                                style: const TextStyle(
                                  color: Color(0xFFD6E7FF),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '🔥 $_currentStreak days streak',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Keep ≥ 8000 steps today to continue.',
                                style: TextStyle(
                                  color: Color(0xCCFFFFFF),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Best (30d)',
                              style: TextStyle(
                                color: Color(0x80DBEFFF),
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '$_bestStreak30',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // check-in grid (last 28 days = 4 weeks)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    decoration: BoxDecoration(
                      color: const Color(0x1A0B2742),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF4FE6FF).withOpacity(.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Check-in (last 28 days)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Teal = reached 8k, Slate = missed',
                          style: TextStyle(
                            color: Color(0x66D6E7FF),
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 星期头
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: const [
                            _WeekHead('Sun'),
                            _WeekHead('Mon'),
                            _WeekHead('Tue'),
                            _WeekHead('Wed'),
                            _WeekHead('Thu'),
                            _WeekHead('Fri'),
                            _WeekHead('Sat'),
                          ],
                        ),
                        const SizedBox(height: 8),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            const double spacing = 6;
                            final double cellW =
                                (constraints.maxWidth - spacing * 6) / 7;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: _last28.map((d) {
                                return SizedBox(
                                  width: cellW,
                                  child: _CheckInCell(day: d),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // history (last 7 days)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    decoration: BoxDecoration(
                      color: const Color(0x1A0B2742),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF4FE6FF).withOpacity(.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'History (last 7 days)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tip: settle steps from Home page to make sure today is counted.',
                          style: TextStyle(
                            color: Color(0x66D6E7FF),
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics:
                          const NeverScrollableScrollPhysics(),
                          itemCount: _last30.length > 7
                              ? 7
                              : _last30.length,
                          itemBuilder: (context, index) {
                            final d = _last30[index];
                            return _HistoryRow(day: d);
                          },
                        ),
                      ],
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

// ---------------- widgets ----------------

class _WeekHead extends StatelessWidget {
  final String text;
  const _WeekHead(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0x99FFFFFF),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CheckInCell extends StatelessWidget {
  final _DayData day;
  const _CheckInCell({required this.day});

  @override
  Widget build(BuildContext context) {
    final bool ok = day.met;
    final String dateLabel = '${day.date.month}/${day.date.day}';

    // 粉蓝主题的小圆标，替换 emoji
    final Widget badge = Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ok
            ? const LinearGradient(
          colors: [
            Color(0xFF00E5FF),
            Color(0xFF2D6BFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : const LinearGradient(
          colors: [
            Color(0x1918293A),
            Color(0x1910294C),
          ],
        ),
        border: Border.all(
          color: ok ? const Color(0xCCBFF7FF) : const Color(0x33D6E7FF),
          width: 1,
        ),
      ),
      child: Icon(
        ok ? Icons.check_rounded : Icons.close_rounded,
        size: 14,
        color: ok ? Colors.white : const Color(0x99FFFFFF),
      ),
    );

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0x080B2742),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ok ? const Color(0x3323E58D) : const Color(0x11FFFFFF),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          badge,
          const SizedBox(height: 4),
          Text(
            dateLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final _DayData day;
  const _HistoryRow({required this.day});

  @override
  Widget build(BuildContext context) {
    final bool ok = day.met;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90, // 比原来 70 宽一点，防止换行
            child: Text(
              _fmtDate(day.date),
              maxLines: 1,
              overflow: TextOverflow.clip, // ← 不要用 fade 了
              softWrap: false,
              style: const TextStyle(
                color: Color(0xE6FFFFFF), // 还是你原来的白色
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: ok
                    ? const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0x0044E5FF)],
                )
                    : const LinearGradient(
                  colors: [Color(0x223F4D61), Color(0x003F4D61)],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${day.steps}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const w = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final weekday = w[d.weekday % 7];
    return '${d.month}/${d.day} · $weekday';
  }
}

// ---------------- bg ----------------

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
    final w = r * math.sqrt(3);

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
      final a = math.pi / 3 * i;
      final pt = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
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

// ---------------- model ----------------

class _DayData {
  _DayData({
    required this.date,
    required this.id,
    required this.steps,
    required this.points,
    required this.met,
  });

  DateTime date;
  String id;
  int steps;
  int points;
  bool met;
}
