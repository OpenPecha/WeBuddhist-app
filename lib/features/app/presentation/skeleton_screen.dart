// This file is the overall app shell with a bottom navigation bar for main sections.
// Tabs: Home, Texts, Recitations, Plans, Settings.

import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/presentation/plan_list.dart';
import 'package:flutter_pecha/features/texts/presentation/library_catalog_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/home/presentation/home_screen.dart';
import 'package:flutter_pecha/features/more/presentation/more_screen.dart';
import 'package:flutter_pecha/features/app/presentation/pecha_bottom_nav_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Riverpod provider for bottom navigation index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class SkeletonScreen extends ConsumerWidget {
  const SkeletonScreen({super.key});

  static final List<Widget> _pages = <Widget>[
    HomeScreen(), // Home tab
    LibraryCatalogScreen(), // Texts tab
    _RecitationsPlaceholder(), // Recitations tab placeholder
    PlanList(), // Plans tab
    MoreScreen(), // Settings/More tab
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(bottomNavIndexProvider);
    return Scaffold(
      body: _pages[selectedIndex],
      bottomNavigationBar: PechaBottomNavBar(),
    );
  }
}

// Placeholder for Recitations screen
class _RecitationsPlaceholder extends StatelessWidget {
  const _RecitationsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recitations')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.handsPraying,
              size: 64,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Recitations',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
