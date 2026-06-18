import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

class HomeShortcutsRow extends StatelessWidget {
  const HomeShortcutsRow({
    super.key,
    this.onPlansTap,
    this.onChantsTap,
    this.onMalaTap,
    this.onTimerTap,
  });

  final VoidCallback? onPlansTap;
  final VoidCallback? onChantsTap;
  final VoidCallback? onMalaTap;
  final VoidCallback? onTimerTap;

  static const _horizontalPadding = 12.0;
  static const _itemSpacing = 8.0;
  static const _borderRadius = 16.0;
  static const _iconSize = 28.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? colorScheme.surfaceContainerHigh : AppColors.greyLight;

    final shortcuts = [
      _HomeShortcutItem(
        icon: AppAssets.homeList,
        label: l10n.home_shortcut_plans,
        onTap: onPlansTap,
      ),
      _HomeShortcutItem(
        icon: AppAssets.homeChants,
        label: l10n.home_chants,
        onTap: onChantsTap,
      ),
      _HomeShortcutItem(
        imageAsset: AppAssets.homeMalaIcon,
        label: l10n.home_mala,
        onTap: onMalaTap,
      ),
      _HomeShortcutItem(
        icon: AppAssets.homeTimer,
        label: l10n.home_timer,
        onTap: onTimerTap,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: Row(
        children: [
          for (var index = 0; index < shortcuts.length; index++) ...[
            if (index > 0) const SizedBox(width: _itemSpacing),
            Expanded(child: shortcuts[index].build(context, cardColor)),
          ],
        ],
      ),
    );
  }
}

class _HomeShortcutItem {
  const _HomeShortcutItem({
    this.icon,
    this.imageAsset,
    required this.label,
    this.onTap,
  }) : assert(
         icon != null || imageAsset != null,
         'Either icon or imageAsset must be provided',
       );

  final IconData? icon;
  final String? imageAsset;
  final String label;
  final VoidCallback? onTap;

  Widget build(BuildContext context, Color cardColor) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.onSurface;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(HomeShortcutsRow._borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIcon(iconColor),
                const SizedBox(),
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        color: iconColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color iconColor) {
    if (imageAsset != null) {
      return Image.asset(
        imageAsset!,
        width: HomeShortcutsRow._iconSize,
        height: HomeShortcutsRow._iconSize,
        color: iconColor,
        colorBlendMode: BlendMode.srcIn,
      );
    }

    return Icon(icon, size: HomeShortcutsRow._iconSize, color: iconColor);
  }
}
