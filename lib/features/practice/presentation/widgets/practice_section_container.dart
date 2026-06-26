import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

class PracticeSectionContainer extends StatelessWidget {
  const PracticeSectionContainer({
    super.key,
    required this.title,
    required this.child,
    this.seeAllLabel,
    this.onSeeAll,
  });

  final String title;
  final Widget child;
  final String? seeAllLabel;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (seeAllLabel != null)
                  GestureDetector(
                    onTap: onSeeAll,
                    child: Text(
                      seeAllLabel!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
