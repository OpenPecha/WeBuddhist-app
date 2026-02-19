import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/ai/presentation/ai_mode_screen.dart';
import 'package:flutter_pecha/features/home/presentation/screens/home_screen.dart';
import 'package:flutter_pecha/features/more/presentation/more_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/practice_screen.dart';
import 'package:flutter_pecha/shared/widgets/appBottomNavBar/app_bottom_nav_bar.dart';
import 'package:flutter_pecha/shared/widgets/appBottomNavBar/app_bottom_nav_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mainNavigationIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  List<AppBottomBarItemModel<int>> _getItems(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return [
      AppBottomBarItemModel(
        type: 0,
        label: localizations.nav_home,
        selectedWidget: const HomeScreen(),
        selectedIconData: AppAssets.homeSelected,
        unSelectedIconData: AppAssets.homeUnselected,
      ),
      AppBottomBarItemModel(
        type: 1,
        label: localizations.nav_texts,
        selectedWidget: const AiModeScreen(),
        selectedIconData: AppAssets.textsSelected,
        unSelectedIconData: AppAssets.textsUnselected,
      ),
      AppBottomBarItemModel(
        type: 2,
        label: localizations.nav_practice,
        selectedWidget: const PracticeScreen(),
        selectedIconData: AppAssets.practiceSelected,
        unSelectedIconData: AppAssets.practiceUnselected,
      ),
      AppBottomBarItemModel(
        type: 3,
        label: localizations.nav_settings,
        selectedWidget: const MoreScreen(),
        selectedIconData: AppAssets.settingsMeSelected,
        unSelectedIconData: AppAssets.settingsMeUnselected,
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _getItems(context);
    final selectedIndex = ref.watch(mainNavigationIndexProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: items[selectedIndex].selectedWidget,
      bottomNavigationBar: AppBottomNavBar(
        items: items,
        onChanged: (index) {
          ref.read(mainNavigationIndexProvider.notifier).state = index;
        },
        type: selectedIndex,
      ),
    );
  }
}
