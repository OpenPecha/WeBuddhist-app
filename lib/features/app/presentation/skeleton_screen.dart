// This file is the overall app shell with a bottom navigation bar for main sections.
// Tabs: Home, Texts, Plans, Settings.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/home/presentation/home_screen.dart';
// TODO: Replace with actual widgets for each tab when available.

/// Riverpod provider for bottom navigation index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class SkeletonScreen extends ConsumerWidget {
  const SkeletonScreen({super.key});

  static final List<Widget> _pages = <Widget>[
    MyHomePage(), // Home tab
    Center(child: Text('Texts')), // Texts tab placeholder
    Center(child: Text('Plans')), // Plans tab placeholder
    Center(child: Text('Settings')), // Settings tab placeholder
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(bottomNavIndexProvider);
    return Scaffold(
      body: _pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: (idx) => ref.read(bottomNavIndexProvider.notifier).state = idx,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Texts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note),
            label: 'Plans',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}