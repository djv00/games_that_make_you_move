import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_steps_tracker/di/injection_container.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/data/models/exchange_history_model.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/manager/exchanges_history/exchanges_history_cubit.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/manager/exchanges_history/exchanges_history_state.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/widgets/exchanges_item.dart';
import 'package:flutter_steps_tracker/generated/l10n.dart';

class ExchangesHistoryPage extends StatelessWidget {
  const ExchangesHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExchangesHistoryCubit>(
      create: (_) {
        final c = getIt<ExchangesHistoryCubit>();
        c.getExchangesHistory();
        return c;
      },
      child: const _ExchangesHistoryView(),
    );
  }
}

class _ExchangesHistoryView extends StatelessWidget {
  const _ExchangesHistoryView();

  Future<void> _refresh(BuildContext context) async {
    await context.read<ExchangesHistoryCubit>().getExchangesHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000612),
      body: Stack(
        children: [
          const _HexBg(),
          SafeArea(
            child: BlocBuilder<ExchangesHistoryCubit, ExchangesHistoryState>(
              builder: (context, state) {
                return state.maybeWhen(
                  loading: () => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  loaded: (exchanges) => RefreshIndicator(
                    onRefresh: () => _refresh(context),
                    color: const Color(0xFF00E5FF),
                    backgroundColor: const Color(0xFF031020),
                    child: _buildBody(context, exchanges: exchanges),
                  ),
                  error: (msg) => RefreshIndicator(
                    onRefresh: () => _refresh(context),
                    color: const Color(0xFF00E5FF),
                    backgroundColor: const Color(0xFF031020),
                    child: _buildBody(context, error: msg),
                  ),
                  orElse: () => RefreshIndicator(
                    onRefresh: () => _refresh(context),
                    color: const Color(0xFF00E5FF),
                    backgroundColor: const Color(0xFF031020),
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
        List<ExchangeHistoryModel>? exchanges,
        String? error,
      }) {
    final items = exchanges ?? const <ExchangeHistoryModel>[];

    return ListView(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exchanges history',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Your redeemed rewards',
                    style: TextStyle(
                      color: Color(0x99D8ECFF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _glassIconButton(Icons.swap_horiz_rounded),
            ],
          ),
        ),

        const SizedBox(height: 6),

        if (error != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _emptyOrErrorCard(
              icon: Icons.warning_amber_rounded,
              title: error,
            ),
          ),
          const SizedBox(height: 14),
        ] else if (items.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _emptyOrErrorCard(
              icon: Icons.history_rounded,
              title: S.of(context).emptyState,
            ),
          ),
          const SizedBox(height: 14),
        ] else ...[
          ...items.map(
                (e) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0x1A0B2742),
                      border: Border.all(
                        color:
                        const Color(0xFF4FE6FF).withOpacity(.14), // 亮一点
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withOpacity(.12),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ExchangesItem(
                      exchangeHistoryItem: e,
                      onDelete: () {
                        context
                            .read<ExchangesHistoryCubit>()
                            .deleteExchange(e.id);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 90),
        ],
      ],
    );
  }

  Widget _emptyOrErrorCard({
    required IconData icon,
    required String title,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0x1A0B2742),
            border: Border.all(
              color: const Color(0xFF4FE6FF).withOpacity(.12),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 24, color: const Color(0xFF35E0FF)),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.3,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 顶部右侧的小玻璃按钮
Widget _glassIconButton(IconData icon) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF35E0FF).withOpacity(.7),
          ),
          gradient: const LinearGradient(
            colors: [
              Color(0x3300E5FF),
              Color(0x0000E5FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    ),
  );
}

// 和其它页面统一的六边形背景
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
