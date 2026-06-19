import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/more/domain/entities/user_stats.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/streak_week_tracker.dart';

class MeStreakCard extends StatelessWidget {
  const MeStreakCard({super.key, required this.streak, this.onTap});

  final StreakStats streak;
  final VoidCallback? onTap;

  static const _borderRadius = 16.0;
  static const _flameColor = Color(0xFFE8630A);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.surfaceWhite;

    return Material(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        side: BorderSide(
          color: isDark ? AppColors.cardBorderDark : AppColors.grey300,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  AppAssets.readerShare,
                  size: 20,
                  color: AppColors.grey600,
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(AppAssets.flame, size: 28, color: _flameColor),
                    const SizedBox(width: 8),
                    Text(
                      l10n.me_day_streak(streak.current),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  l10n.me_best_streak(streak.highest),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.grey300 : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              StreakWeekTracker(practicedDays: streak.week),
            ],
          ),
        ),
      ),
    );
  }
}
