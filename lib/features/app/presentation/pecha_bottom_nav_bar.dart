import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'skeleton_screen.dart';
import 'package:go_router/go_router.dart';

class PechaBottomNavBar extends ConsumerWidget {
  const PechaBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(bottomNavIndexProvider);
    final localizations = AppLocalizations.of(context)!;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home tab hidden - keeping in codebase but not displayed
              _buildNavItem(
                context: context,
                ref: ref,
                index: 0,
                icon: AppAssets.homeUnselected,
                selectedIcon: AppAssets.homeSelected,
                label: localizations.nav_home,
                isSelected: selectedIndex == 0,
              ),
              _buildNavItem(
                context: context,
                ref: ref,
                index: 1,
                icon: AppAssets.textsUnselected,
                selectedIcon: AppAssets.textsSelected,
                label: localizations.nav_texts,
                isSelected: selectedIndex == 1,
              ),
              // _buildNavItem(
              //   context: context,
              //   ref: ref,
              //   index: 1,
              //   icon: FontAwesomeIcons.handsPraying,
              //   selectedIcon: FontAwesomeIcons.handsPraying,
              //   label: localizations.nav_recitations,
              //   isSelected: selectedIndex == 1,
              // ),
              // _buildNavItem(
              //   context: context,
              //   ref: ref,
              //   index: 2,
              //   icon: AppAssets.practiceUnselected,
              //   selectedIcon: AppAssets.practiceSelected,
              //   label: localizations.nav_ai_mode,
              //   isSelected: selectedIndex == 2,
              // ),
              _buildNavItem(
                context: context,
                ref: ref,
                index: 2,
                icon: AppAssets.practiceUnselected,
                selectedIcon: AppAssets.practiceSelected,
                label: localizations.nav_practice,
                isSelected: selectedIndex == 2,
              ),
              _buildNavItem(
                context: context,
                ref: ref,
                index: 3,
                icon: AppAssets.settingsMeUnselected,
                selectedIcon: AppAssets.settingsMeSelected,
                label: localizations.nav_settings,
                isSelected: selectedIndex == 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required WidgetRef ref,
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
  }) {
    final fontSize = 12.0;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Active color uses primary color, inactive uses grey (dark mode friendly)
    final activeColor =
        theme.colorScheme.brightness == Brightness.dark
            ? Colors.white
            : Colors.black;
    final inactiveColor =
        isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600;

    return Expanded(
      child: InkWell(
        onTap: () {
          final currentIndex = ref.read(bottomNavIndexProvider);
          if (index != currentIndex) {
            ref.read(bottomNavIndexProvider.notifier).state = index;
            context.go('/home');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? activeColor : inactiveColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              const SizedBox(height: 2),
              MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(1.0)),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
