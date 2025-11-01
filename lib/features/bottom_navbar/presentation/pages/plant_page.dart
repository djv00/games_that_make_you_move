import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_steps_tracker/utilities/constants/api_path.dart';

class PlantPage extends StatelessWidget {
  const PlantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _boot(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF000612),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _PlantBody(uid: snap.data!);
      },
    );
  }

  // sign in + ensure docs
  Future<String> _boot() async {
    final cur = FirebaseAuth.instance.currentUser ??
        (await FirebaseAuth.instance.signInAnonymously()).user!;
    final uid = cur.uid;

    // users/{uid}
    final userRef = FirebaseFirestore.instance.doc(APIPath.user(uid));
    final userSnap = await userRef.get();
    if (!userSnap.exists) {
      await userRef.set(
        {
          'uid': uid,
          'name': 'Guest',
          'healthPoints': 0,
          'totalSteps': 0,
          'totalCalories': 0,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    // users/{uid}/plant/main
    final plantRef = FirebaseFirestore.instance.doc(APIPath.plant(uid));
    final plantSnap = await plantRef.get();
    if (!plantSnap.exists) {
      await plantRef.set(
        {
          'level': 1,
          'progress': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    return uid;
  }
}

class _PlantBody extends StatelessWidget {
  const _PlantBody({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final userStream =
    FirebaseFirestore.instance.doc(APIPath.user(uid)).snapshots();
    final plantStream =
    FirebaseFirestore.instance.doc(APIPath.plant(uid)).snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF000612),
      body: Stack(
        children: [
          const _HexBg(),
          SafeArea(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: userStream,
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting ||
                    !userSnap.hasData ||
                    userSnap.data?.data() == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final userData = userSnap.data!.data()!;
                final hp = (userData['healthPoints'] ?? 0) as int;
                final name = (userData['name'] ?? 'Guest') as String;

                return StreamBuilder<
                    DocumentSnapshot<Map<String, dynamic>>>(
                  stream: plantStream,
                  builder: (context, plantSnap) {
                    if (plantSnap.connectionState ==
                        ConnectionState.waiting ||
                        !plantSnap.hasData ||
                        plantSnap.data?.data() == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final plantData = plantSnap.data!.data()!;
                    final level = (plantData['level'] ?? 1) as int;
                    final progRaw = plantData['progress'] ?? 0;
                    final progress = progRaw is int
                        ? progRaw
                        : (progRaw as num).round();

                    return _PlantView(
                      uid: uid,
                      userName: name,
                      healthPoints: hp,
                      level: level,
                      progress: progress.clamp(0, 100),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantView extends StatefulWidget {
  const _PlantView({
    required this.uid,
    required this.userName,
    required this.healthPoints,
    required this.level,
    required this.progress,
  });

  final String uid;
  final String userName;
  final int healthPoints;
  final int level;
  final int progress;

  // 起始浇水成本
  static const int kBaseCost = 50;     // Lv1 = 50
  static const int kCostStep = 35;     // B档：每级+35 → 50,85,120,155,190,225
  // 每次浇水长多少（改成10%）
  static const int kGrowPerWater = 10;
  // 最大等级
  static const int kMaxLevel = 7;

  // 图片列表
  static const List<String> _plantImages = [
    'assets/plants/plant_lv1.png',
    'assets/plants/plant_lv2.png',
    'assets/plants/plant_lv3.png',
    'assets/plants/plant_lv4.png',
    'assets/plants/plant_lv5.png',
    'assets/plants/plant_lv6.png',
    'assets/plants/plant_lv7.png',
  ];

  @override
  State<_PlantView> createState() => _PlantViewState();
}

class _PlantViewState extends State<_PlantView> {
  @override
  void didChangeDependencies() {
    // 提前缓存所有图片，避免先1再7的闪一下
    for (final path in _PlantView._plantImages) {
      precacheImage(AssetImage(path), context);
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMax = widget.level >= _PlantView.kMaxLevel;

    // B档成本：线性 50 + (level-1)*35
    final int levelForCost = widget.level <= 0 ? 1 : widget.level;
    final int dynamicCost = _PlantView.kBaseCost +
        (levelForCost - 1) * _PlantView.kCostStep;

    final int idx =
    (widget.level - 1).clamp(0, _PlantView._plantImages.length - 1);
    final String img = _PlantView._plantImages[idx];

    Future<void> _water() async {
      // 1. 先判断点数够不够
      if (widget.healthPoints < dynamicCost) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Not enough points. Need $dynamicCost pts.',
            ),
          ),
        );
        return;
      }

      // 2. 扣用户点数
      final userRef =
      FirebaseFirestore.instance.doc(APIPath.user(widget.uid));
      await userRef.set(
        {'healthPoints': FieldValue.increment(-dynamicCost)},
        SetOptions(merge: true),
      );

      // 3. 植物进度
      final plantRef =
      FirebaseFirestore.instance.doc(APIPath.plant(widget.uid));

      if (isMax) {
        // 到顶只更新时间
        await plantRef.set(
          {
            'level': _PlantView.kMaxLevel,
            'progress': widget.progress,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        // 一次 +10%
        final newProgress = widget.progress + _PlantView.kGrowPerWater;
        if (newProgress >= 100) {
          await plantRef.set(
            {
              'level': math.min(widget.level + 1, _PlantView.kMaxLevel),
              'progress':
              widget.level + 1 >= _PlantView.kMaxLevel ? 100 : 0,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        } else {
          await plantRef.set(
            {
              'progress': newProgress,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      }

      // 4. 写日志
      final logPath =
          '${APIPath.userPlantWaterLogs(widget.uid)}${DateTime.now().toIso8601String()}';
      await FirebaseFirestore.instance.doc(logPath).set({
        'cost': dynamicCost,
        'gain': isMax ? 0 : _PlantView.kGrowPerWater,
        'level': widget.level,
        'at': FieldValue.serverTimestamp(),
      });
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Column(
        children: [
          // header
          Row(
            children: [
              const Text(
                'Plant growth',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x1A00E5FF),
                  border: Border.all(color: const Color(0x33D4EEFF)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.healthPoints} pts',
                      style:
                      const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Hi, ${widget.userName}',
              style: const TextStyle(
                color: Color(0x80D6E7FF),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // info card
          _infoCard(isMax, dynamicCost),

          const SizedBox(height: 20),

          // 图片
          Expanded(
            child: Center(
              child: Image.asset(
                img,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // progress bar
          _progressBar(isMax, dynamicCost),

          const SizedBox(height: 18),

          // 按钮
          SizedBox(
            height: 56,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF4A5CFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(.35),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: _water,
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  isMax ? 'Max level' : 'Water (-$dynamicCost pts)',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(bool isMax, int dynamicCost) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x1A0B2742),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF4FE6FF).withOpacity(.13),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF2D6BFF)],
              ),
            ),
            child: const Icon(Icons.eco_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lv. ${widget.level} plant',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isMax
                      ? 'Max level. You can still water for log.'
                      : 'Each watering +10%, costs $dynamicCost pts.',
                  style: const TextStyle(
                    color: Color(0x99D6E7FF),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${widget.progress}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar(bool isMax, int dynamicCost) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double v =
        isMax ? 1.0 : (widget.progress / 100.0).clamp(0, 1);
        final double fullW = constraints.maxWidth;
        return Column(
          children: [
            Container(
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    Color(0x1A00E5FF),
                    Color(0x1A4A5CFF),
                  ],
                ),
                border: Border.all(
                  color: const Color(0x33D4EEFF),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    width: fullW * v,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: isMax
                            ? const [Color(0xFF30FF9D), Color(0xFF13C684)]
                            : const [Color(0xFF00E5FF), Color(0xFF4A5CFF)],
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      isMax
                          ? 'Max level reached'
                          : 'Growth ${widget.progress}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            if (!isMax)
              Text(
                '+10% per watering · cost $dynamicCost pts',
                style: const TextStyle(
                  color: Color(0x66FFFFFF),
                  fontSize: 11,
                ),
              ),
          ],
        );
      },
    );
  }
}

// background
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
      final pt = Offset(
          center.dx + r * math.cos(a), center.dy + r * math.sin(a));
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
