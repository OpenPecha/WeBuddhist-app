import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/more/domain/entities/user_stats.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/streak_week_tracker.dart';

class StreakShareContent extends StatelessWidget {
  const StreakShareContent({super.key, required this.streak});

  final StreakStats streak;

  static const _flameColor = Color(0xFFE8630A);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.me_streak_share_quote,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppAssets.flame, size: 32, color: _flameColor),
            const SizedBox(width: 8),
            Text(
              l10n.me_streak_days_count(streak.current),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.me_best_streak(streak.highest),
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 28),
        StreakWeekTracker(practicedDays: streak.week, forShare: true),
      ],
    );
  }
}
