import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_steps_tracker/di/injection_container.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/data/models/reward_model.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/manager/rewards/rewards_cubit.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/manager/rewards/rewards_state.dart';
import 'package:flutter_steps_tracker/generated/l10n.dart';

class RewardsItem extends StatefulWidget {
  final RewardModel reward;

  const RewardsItem({
    Key? key,
    required this.reward,
  }) : super(key: key);

  @override
  State<RewardsItem> createState() => _RewardsItemState();
}

class _RewardsItemState extends State<RewardsItem> {
  late RewardsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<RewardsCubit>();
    _cubit.getUserPoints();
  }

  // 生成一段随机兑换码（本地用）
  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return List.generate(12, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  // 最终要塞进二维码里的内容
  String _makeQrPayload() {
    // 如果后端本来给了一个 qrCode，就用后端的
    if (widget.reward.qrCode.isNotEmpty) {
      return widget.reward.qrCode;
    }
    // 否则本地造一条
    final ts = DateTime.now().toIso8601String();
    final code = _generateRandomCode();
    return 'reward:${widget.reward.id ?? 'local'}:$code@$ts';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0x1A0B2742),
            border: Border.all(
              color: const Color(0xFF35E0FF).withOpacity(.25),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRewardImage(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.reward.name.isNotEmpty
                                ? widget.reward.name
                                : 'Reward',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        BlocBuilder<RewardsCubit, RewardsState>(
                          bloc: _cubit,
                          buildWhen: (prev, current) =>
                          current is UserDataLoading ||
                              current is UserDataLoaded,
                          builder: (context, state) {
                            return state.maybeWhen(
                              userDataLoading: () =>
                                  _buildEarnButton(context, isLoading: true),
                              userDataLoaded: (pts) =>
                                  _buildEarnButton(context, points: pts),
                              orElse: () => _buildEarnButton(context),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.reward.description.isNotEmpty
                          ? widget.reward.description
                          : 'Redeem this reward',
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.reward.points} Points',
                      style: const TextStyle(
                        color: Color(0xFFEAF4FF),
                        fontSize: 11.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardImage() {
    final url = widget.reward.imageUrl;
    if (url.isEmpty) {
      return Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF4A5CFF)],
          ),
        ),
        child: const Icon(Icons.card_giftcard, color: Colors.white, size: 28),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: 62,
        height: 62,
        errorWidget: (context, _, __) => Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0x2200E5FF),
          ),
          child: const Icon(Icons.broken_image, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEarnButton(
      BuildContext context, {
        bool isLoading = false,
        int points = 0,
      }) {
    final canRedeem = widget.reward.points <= points;

    return SizedBox(
      height: 30,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: canRedeem
              ? const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF4A5CFF)],
          )
              : const LinearGradient(
            colors: [Color(0x3300E5FF), Color(0x3300E5FF)],
          ),
        ),
        child: TextButton(
          onPressed: (!isLoading)
              ? () {
            if (canRedeem) {
              _showRedeemDialog(context);
            } else {
              _showNotEnoughDialog(context);
            }
          }
              : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            minimumSize: const Size(0, 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: isLoading
              ? const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          )
              : const Text(
            'Earn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ① 积分不足
  void _showNotEnoughDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
          child: _GlassDialogShell(
            title: S.current.notice,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                S.current.pointsLessThanItem,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            primary: _DialogBtn(
              text: S.current.done,
              onTap: () => Navigator.pop(context),
            ),
          ),
        );
      },
    );
  }

  // ② 有积分 → 先确认 → 再扣分 → 再弹二维码/完成
  void _showRedeemDialog(BuildContext context) {
    final hasQrFromServer = widget.reward.qrCode.isNotEmpty;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
          child: _GlassDialogShell(
            title: S.current.notice,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Redeem "${widget.reward.name}" ?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.reward.points} pts',
                  style: const TextStyle(
                    color: Color(0x80FFFFFF),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
            primary: _DialogBtn(
              text: S.current.dummyDone,
              onTap: () async {
                Navigator.pop(context); // 关确认框
                await _cubit.earnAReward(widget.reward); // 真正扣分
                if (hasQrFromServer) {
                  // 后端给了，就显示后端二维码
                  _showQrDialog(context, data: widget.reward.qrCode);
                } else {
                  // 本地随机
                  final payload = _makeQrPayload();
                  _showQrDialog(context, data: payload);
                  // 如果不想显示二维码，只想提示完成，就换成 _showDoneDialog(context);
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _showQrDialog(BuildContext context, {required String data}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
          child: _GlassDialogShell(
            title: S.current.qrCode,
            child: Column(
              children: [
                Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFF020B16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: QrImageView(
                    data: data,
                    version: QrVersions.auto,
                    size: 130,
                    backgroundColor: Colors.transparent,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.white,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.white,
                    ),
                  ),

                ),
                const SizedBox(height: 12),
                Text(
                  widget.reward.name,
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.reward.points} pts',
                  style: const TextStyle(
                    color: Color(0x66FFFFFF),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data,
                  style: const TextStyle(
                    color: Color(0x33FFFFFF),
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            primary: _DialogBtn(
              text: S.current.done,
              onTap: () => Navigator.pop(context),
            ),
          ),
        );
      },
    );
  }

  void _showDoneDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
          child: _GlassDialogShell(
            title: S.current.notice,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Reward redeemed.',
                style: TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            primary: _DialogBtn(
              text: S.current.done,
              onTap: () => Navigator.pop(context),
            ),
          ),
        );
      },
    );
  }
}

/// 通用玻璃弹窗壳
class _GlassDialogShell extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget primary;

  const _GlassDialogShell({
    required this.title,
    required this.child,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: const Color(0xF0121F32),
            border: Border.all(
              color: const Color(0x40FFFFFF),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              child,
              const SizedBox(height: 14),
              primary,
            ],
          ),
        ),
      ),
    );
  }
}

/// 渐变确认按钮
class _DialogBtn extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _DialogBtn({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF4A5CFF)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
