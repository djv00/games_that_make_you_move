import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/data/models/exchange_history_model.dart';
import 'package:flutter_steps_tracker/utilities/constants/assets.dart';
import 'package:flutter_steps_tracker/utilities/constants/enums.dart';
import 'package:intl/intl.dart';

class ExchangesItem extends StatelessWidget {
  final ExchangeHistoryModel exchangeHistoryItem;
  final VoidCallback? onDelete; // ← 新增

  const ExchangesItem({
    Key? key,
    required this.exchangeHistoryItem,
    this.onDelete, // ← 新增
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final date =
    DateFormat.yMMMMd().format(DateTime.parse(exchangeHistoryItem.date));

    final isExchange =
        exchangeHistoryItem.title == ExchangeHistoryTitle.exchange.title;

    final imgUrl =
    isExchange ? AppAssets.exchangesIcon : AppAssets.rewardsIcon;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // 左侧图标
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFC44D),
                  Color(0xFFFF914D),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: imgUrl,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const Icon(
                  Icons.redeem_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 中间文本
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExchange
                      ? exchangeHistoryItem.title
                      : '${exchangeHistoryItem.points} points ${exchangeHistoryItem.title}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  date,
                  style: const TextStyle(
                    color: Color(0x99E4F4FF),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // 右侧 Done 按钮
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00E5FF),
                    Color(0xFF4A5CFF),
                  ],
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
