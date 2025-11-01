import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/pages/exchanges_page.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/pages/home_page.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/pages/leaderboard_page.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/pages/plant_page.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/pages/rewards_page.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({super.key});
  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  int _index = 0;

  // 高对比版
  static const Color kActiveIcon = Colors.white;
  static const Color kActiveText = Colors.white;
  static const Color kInactiveIcon = Color(0xCCFFFFFF);
  static const double kInactiveOpacity = 0.35;
  static final Color kSelectedBg = Colors.black.withOpacity(0.16);

  Widget _buildPage(int i) {
    switch (i) {
      case 0:
        return const HomePage();
      case 1:
        return const ExchangesHistoryPage();
      case 2:
        return const PlantPage();
      case 3:
        return const RewardsPage();
      case 4:
      default:
        return const LeaderboardPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          SafeArea(
            top: true,
            bottom: false,
            child: _buildPage(_index), // ✅ 懒加载
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: w * 0.9,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.045),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(0.22)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _NavItem(
                          icon: CupertinoIcons.house_fill,
                          label: 'Home',
                          selected: _index == 0,
                          activeIcon: kActiveIcon,
                          activeText: kActiveText,
                          inactiveIcon:
                          kInactiveIcon.withOpacity(kInactiveOpacity),
                          selectedBg: kSelectedBg,
                          onTap: () => setState(() => _index = 0),
                        ),
                        _NavItem(
                          icon: Icons.track_changes_rounded,
                          label: 'Exchanges',
                          selected: _index == 1,
                          activeIcon: kActiveIcon,
                          activeText: kActiveText,
                          inactiveIcon:
                          kInactiveIcon.withOpacity(kInactiveOpacity),
                          selectedBg: kSelectedBg,
                          onTap: () => setState(() => _index = 1),
                        ),
                        _NavItem(
                          icon: Icons.spa_rounded,
                          label: 'Plant',
                          selected: _index == 2,
                          activeIcon: kActiveIcon,
                          activeText: kActiveText,
                          inactiveIcon:
                          kInactiveIcon.withOpacity(kInactiveOpacity),
                          selectedBg: kSelectedBg,
                          onTap: () => setState(() => _index = 2),
                        ),
                        _NavItem(
                          icon: Icons.card_giftcard_rounded,
                          label: 'Rewards',
                          selected: _index == 3,
                          activeIcon: kActiveIcon,
                          activeText: kActiveText,
                          inactiveIcon:
                          kInactiveIcon.withOpacity(kInactiveOpacity),
                          selectedBg: kSelectedBg,
                          onTap: () => setState(() => _index = 3),
                        ),
                        _NavItem(
                          icon: Icons.leaderboard_rounded,
                          label: 'Leaderboard',
                          selected: _index == 4,
                          activeIcon: kActiveIcon,
                          activeText: kActiveText,
                          inactiveIcon:
                          kInactiveIcon.withOpacity(kInactiveOpacity),
                          selectedBg: kSelectedBg,
                          onTap: () => setState(() => _index = 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.activeIcon,
    required this.activeText,
    required this.inactiveIcon,
    required this.selectedBg,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color activeIcon;
  final Color activeText;
  final Color inactiveIcon;
  final Color selectedBg;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: selected
            ? BoxDecoration(
          color: selectedBg,
          borderRadius: BorderRadius.circular(14),
        )
            : null,
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? activeIcon : inactiveIcon,
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: activeText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
