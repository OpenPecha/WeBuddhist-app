import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Subtitle shown below the connect tab app bar.
class ConnectHeader extends StatelessWidget {
  const ConnectHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Text(
        context.l10n.connect_subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: subtitleColor,
          fontSize: 15,
          height: 1.4,
        ),
      ),
    );
  }
}
