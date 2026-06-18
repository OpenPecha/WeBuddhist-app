import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/more/domain/entities/user_stats.dart';
import 'package:intl/intl.dart';

enum _WeekDayCellState { today, practiced, missed, future }

class MeStreakCard extends StatelessWidget {
  const MeStreakCard({super.key, required this.streak, this.onShare});

  final StreakStats streak;
  final VoidCallback? onShare;

  static const _borderRadius = 16.0;
  static const _flameColor = Color(0xFFE8630A);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.surfaceWhite;
    final todayWeekday = DateTime.now().weekday;
    final practicedDays = streak.week.toSet();

    return Material(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        side: BorderSide(
          color: isDark ? AppColors.cardBorderDark : AppColors.grey300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  AppAssets.readerShare,
                  size: 20,
                  color: AppColors.grey600,
                ),
                onPressed: onShare,
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.grey600),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                for (var dayIndex = 1; dayIndex <= 7; dayIndex++) ...[
                  if (dayIndex > 1) const SizedBox(width: 4),
                  Expanded(
                    child: _WeekDayColumn(
                      dayIndex: dayIndex,
                      state: _resolveCellState(
                        dayIndex: dayIndex,
                        todayWeekday: todayWeekday,
                        practicedDays: practicedDays,
                      ),
                      locale: intlFormatLocaleOf(context),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  _WeekDayCellState _resolveCellState({
    required int dayIndex,
    required int todayWeekday,
    required Set<int> practicedDays,
  }) {
    if (dayIndex == todayWeekday) return _WeekDayCellState.today;
    if (practicedDays.contains(dayIndex)) return _WeekDayCellState.practiced;
    if (dayIndex < todayWeekday) return _WeekDayCellState.missed;
    return _WeekDayCellState.future;
  }
}

class _WeekDayColumn extends StatelessWidget {
  const _WeekDayColumn({
    required this.dayIndex,
    required this.state,
    required this.locale,
  });

  final int dayIndex;
  final _WeekDayCellState state;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final weekdayLabel =
        DateFormat.E(locale).format(DateTime(2024, 1, dayIndex)).toUpperCase();

    return Column(
      children: [
        Text(
          weekdayLabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.grey600,
            letterSpacing: 0.5,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        _WeekDayCell(state: state),
      ],
    );
  }
}

class _WeekDayCell extends StatelessWidget {
  const _WeekDayCell({required this.state});

  final _WeekDayCellState state;

  static const _cellSize = 36.0;
  static const _flameColor = Color(0xFFE8630A);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.cardDark : AppColors.surfaceWhite;
    final missedColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.grey300;
    final todayBorderColor = isDark ? AppColors.grey300 : AppColors.grey900;

    return SizedBox(
      width: _cellSize,
      height: _cellSize,
      child: switch (state) {
        _WeekDayCellState.today => DecoratedBox(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: todayBorderColor, width: 1.5),
          ),
          child: const Center(
            child: Icon(AppAssets.flame, size: 16, color: _flameColor),
          ),
        ),
        _WeekDayCellState.practiced => DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? AppColors.grey300 : AppColors.grey900,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              AppAssets.check,
              size: 16,
              color: isDark ? AppColors.grey900 : Colors.white,
            ),
          ),
        ),
        _WeekDayCellState.missed => DecoratedBox(
          decoration: BoxDecoration(
            color: missedColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '—',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        _WeekDayCellState.future => const SizedBox.shrink(),
      },
    );
  }
}
