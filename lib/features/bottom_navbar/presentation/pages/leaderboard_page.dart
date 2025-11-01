// lib/features/bottom_navbar/presentation/pages/leaderboard_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_steps_tracker/core/data/models/user_model.dart';
import 'package:flutter_steps_tracker/di/injection_container.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/manager/leaderboard/leaderboard_cubit.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/manager/leaderboard/leaderboard_state.dart';
import 'package:flutter_steps_tracker/generated/l10n.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final c = getIt<LeaderboardCubit>();
        c.getUsers();
        return c;
      },
      child: const _LeaderboardView(),
    );
  }
}

class _LeaderboardView extends StatelessWidget {
  const _LeaderboardView();

  static const _bgGradient = LinearGradient(
    colors: [
      Color(0xFF020916),
      Color(0xFF031B2E),
      Color(0xFF042235),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  Future<void> _refresh(BuildContext context) async {
    await context.read<LeaderboardCubit>().getUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020916),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(gradient: _bgGradient),
          child: BlocBuilder<LeaderboardCubit, LeaderboardState>(
            builder: (context, state) {
              return state.maybeWhen(
                loading: () => const Center(child: CircularProgressIndicator()),
                loaded: (users) => RefreshIndicator(
                  color: Colors.cyanAccent,
                  onRefresh: () => _refresh(context),
                  child: _body(context, users),
                ),
                error: (msg) => RefreshIndicator(
                  onRefresh: () => _refresh(context),
                  child: _errorBody(context, msg ?? S.of(context).emptyState),
                ),
                orElse: () => RefreshIndicator(
                  onRefresh: () => _refresh(context),
                  child: _errorBody(context, S.of(context).emptyState),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, List<UserModel> users) {
    final top1 = users.isNotEmpty ? users[0] : null;
    final top2 = users.length > 1 ? users[1] : null;
    final top3 = users.length > 2 ? users[2] : null;
    final rest = users.length > 3 ? users.sublist(3) : const <UserModel>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Leaderboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.2,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Top walkers of today',
                    style: TextStyle(
                      color: Color(0x99D4E9FF),
                      fontSize: 12.8,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF26E7FF).withOpacity(.7),
                  width: 1.1,
                ),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF26E7FF).withOpacity(.07),
                    const Color(0xFF26E7FF).withOpacity(.01),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF26E7FF).withOpacity(.35),
                    blurRadius: 14,
                  )
                ],
              ),
              child: const Icon(
                Icons.query_stats_rounded,
                size: 19,
                color: Color(0xFF26E7FF),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _Top3Podium(
          top1: top1,
          top2: top2,
          top3: top3,
        ),

        const SizedBox(height: 16),

        _GlassCard(
          borderRadius: 30,
          child: rest.isEmpty
              ? Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
            child: _emptyCard(context, S.of(context).emptyState),
          )
              : Column(
            children: List.generate(rest.length, (i) {
              final u = rest[i];
              return _RankRow(
                rank: i + 4,
                name: u.name ?? '—',
                steps: u.totalSteps ?? 0,
                isLast: i == rest.length - 1,
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _errorBody(BuildContext context, String msg) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
      children: [
        const Text(
          'Leaderboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        _emptyCard(context, msg),
      ],
    );
  }

  Widget _emptyCard(BuildContext context, String text) {
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            const Text('😶', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const _GlassCard({
    required this.child,
    this.borderRadius = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.04),
            Colors.white.withOpacity(0.01),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0FF0FF).withOpacity(.25),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: child,
        ),
      ),
    );
  }
}

// ====================== 顶部 3 人 ======================
class _Top3Podium extends StatelessWidget {
  final UserModel? top1;
  final UserModel? top2;
  final UserModel? top3;

  const _Top3Podium({
    required this.top1,
    required this.top2,
    required this.top3,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 32,
      child: SizedBox(
        height: 240,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final col = w / 3;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 左：2号柱
                Positioned(
                  bottom: -2,
                  left: col * 0 + (col - 82) / 2,
                  child: _GlassPedestal(
                    width: 82,
                    height: 86,
                    colors: const [
                      Color(0x4416B5FF),
                      Color(0x0016B5FF),
                    ],
                    borderColor: const Color(0x3380D4FF),
                    name: top2?.name ?? '—',
                    steps: top2?.totalSteps ?? 0,
                  ),
                ),
                // 中：1号柱（最高）
                Positioned(
                  bottom: -2,
                  left: col * 1 + (col - 98) / 2,
                  child: _GlassPedestal(
                    width: 98,
                    height: 105,
                    // 这里原来是青蓝色，改成跟rank 1差不多的黄橙，但更浅
                    colors: const [
                      Color(0x55FFB74D), // 上面：半透明黄
                      Color(0x00FFB74D), // 下面：渐隐
                    ],
                    borderColor: const Color(0x33FFB74D),
                    name: top1?.name ?? '—',
                    steps: top1?.totalSteps ?? 0,
                  ),
                ),
                // 右：3号柱
                Positioned(
                  bottom: -2,
                  left: col * 2 + (col - 82) / 2,
                  child: _GlassPedestal(
                    width: 82,
                    height: 74,
                    colors: const [
                      Color(0x55FF6E9D),
                      Color(0x00FF6E9D),
                    ],
                    borderColor: const Color(0x33FF6E9D),
                    name: top3?.name ?? '—',
                    steps: top3?.totalSteps ?? 0,
                  ),
                ),

                // 中间第一名头像 ← 再往上移
                Positioned(
                  top: 3, // ← 这里从 10 改成 -4，让头像和数字再高一点
                  left: col * 1 + (col - 96) / 2,
                  child: const _TopUser(
                    rank: 1,
                    isMain: true,
                  ),
                ),
                // 左二头像
                Positioned(
                  top: 39,
                  left: col * 0 + (col - 78) / 2,
                  child: const _TopUser(
                    rank: 2,
                    color: LinearGradient(
                      colors: [Color(0xFF1BB3FF), Color(0xFF325BFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // 右三头像
                Positioned(
                  top: 53,
                  left: col * 2 + (col - 78) / 2,
                  child: const _TopUser(
                    rank: 3,
                    color: LinearGradient(
                      colors: [Color(0xFFFF6E9D), Color(0xFF8B56FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ====================== 玻璃柱 ======================
class _GlassPedestal extends StatelessWidget {
  final double width;
  final double height;
  final List<Color> colors;
  final Color borderColor;
  final String name;
  final int steps;

  const _GlassPedestal({
    required this.width,
    required this.height,
    required this.colors,
    required this.borderColor,
    required this.name,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatSteps(steps),
                  style: TextStyle(
                    color: Colors.white.withOpacity(.75),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatSteps(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    final r = s.split('').reversed.toList();
    final buf = StringBuffer();
    for (var i = 0; i < r.length; i++) {
      if (i != 0 && i % 3 == 0) buf.write(',');
      buf.write(r[i]);
    }
    return buf.toString().split('').reversed.join();
  }
}

// ====================== 头像 ======================
class _TopUser extends StatelessWidget {
  final int rank;
  final bool isMain;
  final LinearGradient? color;

  const _TopUser({
    required this.rank,
    this.isMain = false,
    this.color,
  });


  @override
  Widget build(BuildContext context) {
    final avatarSize = isMain ? 96.0 : 78.0;

    final gradient = color ??
        const LinearGradient(
          colors: [Color(0xFF27DFFF), Color(0xFF4E6DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

    // 1/2/3 只是颜色不同，大小都一样
    final Color badgeBg;
    final Color badgeText;
    switch (rank) {
      case 1:
        badgeBg = const Color(0xFFFFB74D);
        badgeText = Colors.black87;
        break;
      case 2:
        badgeBg = const Color(0xFF3BA9FF);
        badgeText = Colors.white;
        break;
      case 3:
        badgeBg = const Color(0xFFFF5E9C);
        badgeText = Colors.white;
        break;
      default:
        badgeBg = Colors.white24;
        badgeText = Colors.white;
    }

    return Column(
      children: [
        // 👇 不再区分 isMain
        Container(
          width: 44,
          height: 25,
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(.18)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: TextStyle(
              color: badgeText,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(.55),
                blurRadius: 22,
              )
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
      ],
    );
  }

}

// ====================== 列表行 ======================
class _RankRow extends StatelessWidget {
  final int rank;
  final String name;
  final int steps;
  final bool isLast;

  const _RankRow({
    required this.rank,
    required this.name,
    required this.steps,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:
          const EdgeInsets.only(left: 14, right: 14, top: 12, bottom: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF27DFFF), Color(0xFF5C4BFF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF27DFFF).withOpacity(.45),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_formatSteps(steps)} steps',
                      style: const TextStyle(
                        color: Color(0x88D4E9FF),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _MiniBars(value: steps),
              const SizedBox(width: 10),
              Text(
                _formatSteps(steps),
                style: const TextStyle(
                  color: Color(0xFF2BE0FF),
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 62, right: 10),
            color: Colors.white.withOpacity(.015),
          ),
      ],
    );
  }

  String _formatSteps(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    final rev = s.split('').reversed.toList();
    final buf = StringBuffer();
    for (int i = 0; i < rev.length; i++) {
      if (i != 0 && i % 3 == 0) buf.write(',');
      buf.write(rev[i]);
    }
    return buf.toString().split('').reversed.join();
  }
}

// ====================== 右侧小条形图 ======================
class _MiniBars extends StatelessWidget {
  final int value;

  const _MiniBars({required this.value});

  @override
  Widget build(BuildContext context) {
    final percent = (value % 10000) / 10000.0;
    return SizedBox(
      width: 54,
      height: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(5, (i) {
          final h = 6 + (i * 3) + percent * 6;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              height: h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2BE0FF),
                    Color(0xFF6E56FF),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
