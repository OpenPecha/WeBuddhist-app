import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/calendar/domain/entities/tibetan_calendar_day.dart';
import 'package:flutter_pecha/features/calendar/domain/models/moon_phase.dart';
import 'package:flutter_pecha/features/calendar/presentation/calendar_l10n_utils.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/tibetan_calendar_providers.dart';
import 'package:flutter_pecha/features/calendar/presentation/widgets/moon_phase_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Home-screen summary card showing today's lunar date and moon phase.
///
/// Data comes from `GET /calendar/today` ([todayCalendarDayProvider]); while
/// that's in flight (or offline) it shows the local-engine value so the card
/// never blanks or spins. Tapping opens the full [TibetanCalendarScreen].
class HomeCalendarCard extends ConsumerWidget {
  const HomeCalendarCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    // Instant engine value, upgraded to the backend's once it resolves.
    final engineToday = TibetanCalendarDay.fromEngine(
      dateOnly(DateTime.now()),
      ref.watch(tibetanCalendarServiceProvider),
    );
    final day =
        ref.watch(todayCalendarDayProvider).asData?.value ?? engineToday;
    final phase = moonPhaseForLunarDay(day.lunarDay);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(AppRoutes.calendar),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                MoonPhaseIcon(phase: phase, size: 44),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.calendar_day_month(day.lunarDay, day.lunarMonth),
                        strutStyle: context.tibetanStrutStyle(
                          theme.textTheme.titleMedium?.fontSize ?? 16,
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        moonPhaseLabel(l10n, phase),
                        strutStyle: context.tibetanStrutStyle(
                          theme.textTheme.bodyMedium?.fontSize ?? 14,
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
