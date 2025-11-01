import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_steps_tracker/di/injection_container.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/data/models/reward_model.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/manager/rewards/rewards_cubit.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/manager/rewards/rewards_state.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/widgets/rewards_item.dart';
import 'package:flutter_steps_tracker/generated/l10n.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RewardsCubit>(
      create: (_) {
        final cubit = getIt<RewardsCubit>();
        cubit.getRewards();
        return cubit;
      },
      child: const _RewardsView(),
    );
  }
}

class _RewardsView extends StatelessWidget {
  const _RewardsView();

  Future<void> _refresh(BuildContext context) async {
    context.read<RewardsCubit>().getRewards();
  }

  static const Color _bg = Color(0xFF000612);
  static const Color _neon = Color(0xFF35E0FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          const _HexBgRewards(),
          SafeArea(
            child: BlocBuilder<RewardsCubit, RewardsState>(
              builder: (context, state) {
                return state.maybeWhen(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: _neon),
                  ),
                  loaded: (rewards) => RefreshIndicator(
                    color: _neon,
                    onRefresh: () => _refresh(context),
                    child: _buildBody(context, rewards: rewards),
                  ),
                  error: (msg) => RefreshIndicator(
                    color: _neon,
                    onRefresh: () => _refresh(context),
                    child: _buildBody(context, error: msg),
                  ),
                  orElse: () => RefreshIndicator(
                    color: _neon,
                    onRefresh: () => _refresh(context),
                    child: _buildBody(context),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, {
        List<RewardModel>? rewards,
        String? error,
      }) {
    final items = rewards ?? const <RewardModel>[];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // header
        Row(
          children: [
            const Text(
              'Rewards',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              S.of(context).availableRewards,
              style: const TextStyle(
                color: Color(0x99D5E7FF),
                fontSize: 12.5,
              ),
            ),
            const Spacer(),
            _neonIconBtn(Icons.card_giftcard_rounded),
          ],
        ),

        const SizedBox(height: 14),

        // 🔥 实时积分卡
        const _UserPointsCard(),

        const SizedBox(height: 18),

        if (error != null) ...[
          _GlassCard(
            child: _emptyOrErrorLine(
              icon: Icons.warning_amber_rounded,
              text: error,
            ),
          ),
          const SizedBox(height: 14),
        ],

        if (items.isEmpty && error == null)
          _GlassCard(
            child: _emptyOrErrorLine(
              icon: Icons.redeem_rounded,
              text: S.of(context).emptyState,
            ),
          )
        else
          ...items.map(
                (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _GlassCard(
                child: RewardsItem(reward: e),
              ),
            ),
          ),
      ],
    );
  }

  static Widget _emptyOrErrorLine({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF00E5FF).withValues(alpha: .12),
            border: Border.all(
              color: const Color(0xFF00E5FF).withValues(alpha: .35),
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.8,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

/// 实时显示 users/{uid}.healthPoints
class _UserPointsCard extends StatelessWidget {
  const _UserPointsCard();

  Future<User> _ensureUser() async {
    final cur = FirebaseAuth.instance.currentUser;
    if (cur != null) return cur;
    final cred = await FirebaseAuth.instance.signInAnonymously();
    return cred.user!;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _ensureUser(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const _GlassCard(
            child: SizedBox(
              height: 44,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final uid = snap.data!.uid;
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.doc('users/$uid').snapshots(),
          builder: (context, userSnap) {
            final data = userSnap.data?.data() ?? {};
            final hp = (data['healthPoints'] ?? 0) as int;

            return _GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF4A5CFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.stars_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your points',
                          style: TextStyle(
                            color: Color(0xE6FFFFFF),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Health points / Step points',
                          style: TextStyle(
                            color: Color(0x88FFFFFF),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$hp pts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// 玻璃卡片
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0x1A0B2742),
            border: Border.all(
              color: const Color(0xFF35E0FF).withValues(alpha: .25),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3300D1FF),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 背景六边形
class _HexBgRewards extends StatelessWidget {
  const _HexBgRewards();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HexPainterRewards(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF020B16),
              Color(0xFF021C31),
              Color(0xFF030F29),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}

class _HexPainterRewards extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x101EC7FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const r = 30.0;
    final w = r * sqrt(3);

    for (double y = 40; y < size.height; y += r * 1.5) {
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
        color: const Color(0xFF00E5FF).withValues(alpha: .7),
        width: 1.2,
      ),
      gradient: LinearGradient(
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: .12),
          const Color(0xFF00E5FF).withValues(alpha: .0),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF00E5FF).withValues(alpha: .4),
          blurRadius: 12,
        ),
      ],
    ),
    child: Icon(icon, color: const Color(0xFF00E5FF), size: 20),
  );
}
