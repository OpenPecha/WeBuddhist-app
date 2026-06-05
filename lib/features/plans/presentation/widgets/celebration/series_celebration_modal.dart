import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';

/// Full-screen dialog shown when the user completes the last plan in a series.
/// Matches Figma "Celebration — Series completion".
class SeriesCelebrationModal extends StatelessWidget {
  const SeriesCelebrationModal({
    super.key,
    required this.series,
    required this.onFindAnotherSeries,
    required this.onStay,
  });

  final Series series;
  final VoidCallback onFindAnotherSeries;
  final VoidCallback onStay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalDays = series.totalDays;
    final totalPlans = series.plans.length;

    final metaLine = [
      '$totalPlans ${totalPlans == 1 ? "plan" : "plans"}',
      if (totalDays > 0) '$totalDays days',
    ].join(' · ');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Large filled checkmark for series
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFB800), Color(0xFFFF8C00)],
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // "SERIES DONE" label
            const Text(
              'SERIES DONE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Color(0xFFFF8C00),
              ),
            ),
            const SizedBox(height: 8),
            // Series title
            Text(
              series.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            // "X plans · Y days"
            Text(
              metaLine,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // "Find another series" — primary dark button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onFindAnotherSeries,
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.celebration_series_find_another),
              ),
            ),
            const SizedBox(height: 10),
            // "Stay & revisit any plan" — text button
            TextButton(
              onPressed: onStay,
              child: Text(
                l10n.celebration_series_stay,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
