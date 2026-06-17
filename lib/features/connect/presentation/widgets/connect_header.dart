import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/connect/presentation/screens/group_search_screen.dart';

class ConnectHeader extends StatelessWidget {
  const ConnectHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.nav_connect,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: context.isTibetanLocale ? 22 : 28,
                    height: context.isTibetanLocale ? 1.2 : null,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const GroupSearchScreen(),
                    ),
                  );
                },
                icon: Icon(
                  AppAssets.exploreUnselected,
                  color: theme.colorScheme.onSurface,
                ),
                tooltip: context.l10n.text_search,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.connect_subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: subtitleColor,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
