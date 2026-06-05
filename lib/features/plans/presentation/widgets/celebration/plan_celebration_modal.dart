import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';

/// Dialog shown when the user completes the last day of a plan.
/// Shows "Continue to [next plan]" if the plan is part of a series with a next plan.
/// Matches Figma "Celebration — Plan completion".
class PlanCelebrationModal extends StatelessWidget {
  const PlanCelebrationModal({
    super.key,
    required this.planTitle,
    required this.totalDays,
    this.nextPlanTitle,
    required this.onContinue,
  });

  final String planTitle;
  final int totalDays;

  /// Title of the next plan in the series. Null for standalone or last plan.
  final String? nextPlanTitle;

  /// Called when the primary action button is tapped.
  /// For series plans: navigates to next plan.
  /// For standalone / last plan: dismisses (back to home).
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final hasNextPlan = nextPlanTitle != null;

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
            // "PLAN DONE" label
            Text(
              l10n.celebration_plan_done,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            // Plan title
            Text(
              planTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (hasNextPlan) ...[
              Text(
                l10n.celebration_plan_subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
            ],
            // Duration
            Text(
              l10n.celebration_plan_days(totalDays),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Primary action button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  hasNextPlan
                      ? l10n.celebration_continue_to(nextPlanTitle!)
                      : l10n.celebration_back_to_home,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
