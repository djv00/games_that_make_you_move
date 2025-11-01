import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BottomNavbarFallback extends StatefulWidget {
  const BottomNavbarFallback({super.key});
  @override
  State<BottomNavbarFallback> createState() => _BottomNavbarFallbackState();
}

class _BottomNavbarFallbackState extends State<BottomNavbarFallback> {
  int _index = 0;

  final _pages = const [
    _TempHome(),
    _TempExchanges(),
    _TempRewards(),
    _TempLeaderboard(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Steps Tracker (safe mode)')),
      body: SafeArea(child: IndexedStack(index: _index, children: _pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(CupertinoIcons.home),   label: 'Home'),
          NavigationDestination(icon: Icon(Icons.track_changes),   label: 'Exchanges'),
          NavigationDestination(icon: Icon(Icons.card_giftcard),   label: 'Rewards'),
          NavigationDestination(icon: Icon(Icons.developer_board), label: 'Leaderboard'),
        ],
      ),
    );
  }
}

class _TempHome extends StatelessWidget {
  const _TempHome();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Home • Ready'));
}
class _TempExchanges extends StatelessWidget {
  const _TempExchanges();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Exchanges • Ready'));
}
class _TempRewards extends StatelessWidget {
  const _TempRewards();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Rewards • Ready'));
}
class _TempLeaderboard extends StatelessWidget {
  const _TempLeaderboard();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Leaderboard • Ready'));
}
