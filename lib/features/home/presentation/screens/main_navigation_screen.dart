import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/more/presentation/more_screen.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/home/presentation/screens/home_screen.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/practice_screen.dart';
import 'package:flutter_pecha/shared/widgets/appBottomNavBar/app_bottom_nav_bar.dart';
import 'package:flutter_pecha/shared/widgets/appBottomNavBar/app_bottom_nav_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom-nav tabs in display order. The enum index matches the position in
/// [MainNavigationScreen._getItems] and the int value stored in
/// [mainNavigationIndexProvider]; prefer `MainTab.x.index` over raw numbers.
enum MainTab { home, practice, me }

final mainNavigationIndexProvider = StateProvider<int>(
  (ref) => MainTab.home.index,
);

/// One-shot guard for the launch-time auto-switch to the Practice tab. Set to
/// true the first time [userRoutineProvider] resolves OR the user manually
/// taps a tab, ensuring the auto-switch never fights a deliberate choice and
/// never re-fires on later provider invalidations within the same session.
final initialPracticeTabResolvedProvider = StateProvider<bool>((ref) => false);

/// Holds an enrolled plan that should be opened after the home screen's
/// notification-permission flow completes. Set during onboarding completion,
/// consumed once by [HomeScreen], and cleared immediately after navigation.
final pendingOnboardingPlanProvider = StateProvider<UserPlansModel?>(
  (ref) => null,
);

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
        label: localizations.nav_practice,
        selectedWidget: const PracticeScreen(),
        selectedIconData: AppAssets.practiceSelected,
        unSelectedIconData: AppAssets.practiceUnselected,
      ),
      AppBottomBarItemModel(
        type: 2,
        label: localizations.nav_me,
        selectedWidget: const MoreScreen(),
        selectedIconData: AppAssets.meSelected,
        unSelectedIconData: AppAssets.meUnselected,
      ),
      //  AppBottomBarItemModel(
      //   type: 1,
      //   label: localizations.nav_learn,
      //   selectedWidget: const LearnScreen(),
      //   selectedIconData: AppAssets.textsSelected,
      //   unSelectedIconData: AppAssets.textsUnselected,
      // ),
      //    AppBottomBarItemModel(
      //   type: 3,
      //   label: localizations.nav_connect,
      //   selectedWidget: const ConnectScreen(),
      //   selectedIconData: AppAssets.connectSelected,
      //   unSelectedIconData: AppAssets.connectUnselected,
      // ),
      // AppBottomBarItemModel(
      //   type: 4,
      //   label: localizations.nav_explore,
      //   selectedWidget: const ExploreScreen(),
      //   selectedIconData: AppAssets.exploreSelected,
      //   unSelectedIconData: AppAssets.exploreUnselected,
      // ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _getItems(context);
    final selectedIndex = ref.watch(mainNavigationIndexProvider);

    // Open Practice on launch if the logged-in user already has a routine.
    // userRoutineProvider returns null for guests / not-logged-in / auth still
    // loading, so those cases fall through to Home with no side effects. The
    // resolved flag makes this fire at most once per session and prevents it
    // from clobbering a manual tab tap that landed first.
    ref.listen<AsyncValue<RoutineData?>>(userRoutineProvider, (prev, next) {
      if (ref.read(initialPracticeTabResolvedProvider)) return;
      if (ref.read(authProvider).isLoading) return;
      next.whenData((routine) {
        ref.read(initialPracticeTabResolvedProvider.notifier).state = true;
        if (routine != null && routine.hasItems) {
          ref.read(mainNavigationIndexProvider.notifier).state =
              MainTab.practice.index;
        }
      });
    });

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: items[selectedIndex].selectedWidget,
      bottomNavigationBar: AppBottomNavBar(
        items: items,
        onChanged: (index) {
          ref.read(initialPracticeTabResolvedProvider.notifier).state = true;
          ref.read(mainNavigationIndexProvider.notifier).state = index;
        },
        type: selectedIndex,
      ),
    );
  }
}
