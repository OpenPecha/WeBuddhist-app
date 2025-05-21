import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'skeleton_screen.dart';
import 'package:go_router/go_router.dart';

class PechaBottomNavBar extends ConsumerWidget {
  const PechaBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(bottomNavIndexProvider);
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (idx) {
          if (idx != selectedIndex) {
            // Update state
            ref.read(bottomNavIndexProvider.notifier).state = idx;
            // Navigate to root of the selected tab
            context.go('/home');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Texts'),
          BottomNavigationBarItem(icon: Icon(Icons.check_box), label: 'Plans'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
        ],
      ),
    );
  }
}
