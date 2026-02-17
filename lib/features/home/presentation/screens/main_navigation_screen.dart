import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/ai/presentation/ai_mode_screen.dart';
import 'package:flutter_pecha/features/home/presentation/screens/home_screen.dart';
import 'package:flutter_pecha/features/more/presentation/more_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/practice_screen.dart';
import 'package:flutter_pecha/shared/widgets/appBottomNavBar/app_bottom_nav_bar.dart';
import 'package:flutter_pecha/shared/widgets/appBottomNavBar/app_bottom_nav_item.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

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
  Widget build(BuildContext context) {
    final items = _getItems(context);
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: items[_currentIndex].selectedWidget,
      bottomNavigationBar: AppBottomNavBar(
        items: items,
        onChanged: (index) {
          setState(() => _currentIndex = index);
        },
        type: _currentIndex,
      ),
    );
  }
}
