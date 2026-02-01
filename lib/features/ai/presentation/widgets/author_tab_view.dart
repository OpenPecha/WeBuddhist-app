import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Tab view for author search (Coming Soon placeholder)
class AuthorTabView extends StatelessWidget {
  const AuthorTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_rounded,
              size: 80,
              color: isDarkMode ? AppColors.grey500 : AppColors.grey400,
            ),
            const SizedBox(height: 24),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.grey400 : AppColors.grey600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Author search will be available soon',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? AppColors.grey500 : AppColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
