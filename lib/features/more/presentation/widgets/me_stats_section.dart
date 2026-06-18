import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/more/domain/entities/user_stats.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/me_streak_card.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class MeStatsSection extends StatelessWidget {
  const MeStatsSection({super.key, required this.stats});

  final UserStats stats;

  static const _horizontalPadding = 20.0;
  static const _cardSpacing = 12.0;
  static const _borderRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = intlFormatLocaleOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.surfaceWhite;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _horizontalPadding,
        24,
        _horizontalPadding,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.me_my_stats,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          MeStreakCard(
            streak: stats.streak,
            onShare: () => _shareStreak(context),
          ),
          const SizedBox(height: _cardSpacing),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: l10n.me_accumulation,
                  icon: Image.asset(
                    AppAssets.homeMalaIcon,
                    width: 22,
                    height: 22,
                    color: Theme.of(context).colorScheme.onSurface,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                  value: _formatCompactCount(stats.totalAccumulated, locale),
                  unit: l10n.me_counts,
                  cardColor: cardColor,
                ),
              ),
              const SizedBox(width: _cardSpacing),
              Expanded(
                child: _StatCard(
                  label: l10n.home_timer,
                  icon: Icon(
                    AppAssets.homeTimer,
                    size: 22,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  value: _formatCompactCount(
                    (stats.totalTimerSeconds / 60).round(),
                    locale,
                  ),
                  unit: l10n.me_minutes,
                  cardColor: cardColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: _cardSpacing),
          _PracticeDaysCard(
            days: stats.totalPracticeDays,
            cardColor: cardColor,
          ),
        ],
      ),
    );
  }

  void _shareStreak(BuildContext context) {
    final l10n = context.l10n;
    SharePlus.instance.share(
      ShareParams(
        text: l10n.me_streak_share_message(stats.streak.current, l10n.appTitle),
      ),
    );
  }

  String _formatCompactCount(int count, String locale) {
    if (count >= 1000000) {
      final value = count / 1000000;
      return '${_trimTrailingZero(value.toStringAsFixed(1))}M';
    }
    if (count >= 1000) {
      final value = count / 1000;
      return '${_trimTrailingZero(value.toStringAsFixed(1))}k';
    }
    return NumberFormat.decimalPattern(locale).format(count);
  }

  String _trimTrailingZero(String value) {
    return value.endsWith('.0') ? value.substring(0, value.length - 2) : value;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.unit,
    required this.cardColor,
  });

  final String label;
  final Widget icon;
  final String value;
  final String unit;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MeStatsSection._borderRadius),
        side: BorderSide(
          color: isDark ? AppColors.cardBorderDark : AppColors.grey300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.grey600),
                ),
                icon,
              ],
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeDaysCard extends StatelessWidget {
  const _PracticeDaysCard({required this.days, required this.cardColor});

  final int days;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MeStatsSection._borderRadius),
        side: BorderSide(
          color: isDark ? AppColors.cardBorderDark : AppColors.grey300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: '$days',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: ' ${l10n.me_days_plan_practiced_suffix}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            Icon(
              AppAssets.homeList,
              size: 24,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }
}
