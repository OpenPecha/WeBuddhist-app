import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';

/// Full-screen dialog shown when the user completes all tasks for a non-last day.
/// Matches Figma "Celebration — Daily completion".
class DayCelebrationModal extends StatelessWidget {
  const DayCelebrationModal({
    super.key,
    required this.dayNumber,
    required this.totalDays,
    required this.onDismiss,
  });

  final int dayNumber;
  final int totalDays;
  final VoidCallback onDismiss;

  static const _headings = [
    'Great work!',
    'Well done!',
    "You're on a roll!",
    'Keep it up!',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final heading = _headings[Random().nextInt(_headings.length)];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

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
            // Checkmark circle
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor, width: 2.5),
              ),
              child: Icon(Icons.check_rounded, size: 36, color: primaryColor),
            ),
            const SizedBox(height: 16),
            // "DAY DONE" label
            Text(
              l10n.celebration_day_done,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            // Random heading
            Text(
              heading,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // "Day X of Y complete."
            Text(
              l10n.celebration_day_complete(dayNumber, totalDays),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // "You showed up..."
            Text(
              l10n.celebration_day_body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Back to home button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onDismiss,
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.celebration_back_to_home),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
