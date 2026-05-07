import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('PlanSubtaskCompletion');

/// Fires the complete-subtask API call for the current item in [navContext].
///
/// Callers should invoke [invalidatePlanProviders] **synchronously before
/// navigating away** so that plan-day providers refresh regardless of when
/// this async call finishes and the widget's `ref` is still valid.
///
/// No-ops when:
/// - [navContext] is null or source is not [NavigationSource.plan]
/// - the current item has no `subtaskId` (preview mode)
/// - the subtask is already completed
void completeCurrentPlanSubtask(WidgetRef ref, NavigationContext? navContext) {
  if (navContext == null || navContext.source != NavigationSource.plan) {
    return;
  }

  final currentItem = navContext.currentItem;
  if (currentItem == null) return;

  final subtaskId = currentItem.subtaskId;
  if (subtaskId == null || subtaskId.isEmpty) return;
  if (currentItem.isCompleted) return;

  Future.microtask(() async {
    try {
      final result = await ref.read(
        completeSubTaskFutureProvider(subtaskId).future,
      );
      result.fold(
        (failure) =>
            _logger.error('Failed to complete subtask: ${failure.message}'),
        (_) => _logger.info('Marked subtask $subtaskId as complete'),
      );
    } on StateError {
      // Widget was disposed before the API call finished — the request was
      // already in-flight and providers were invalidated synchronously by the
      // caller before navigation, so the UI will still reflect the change.
    } catch (e) {
      _logger.error('Failed to complete subtask $subtaskId', e);
    }
  });
}

/// Invalidates the plan-day providers so the UI refreshes on return.
///
/// Call this **synchronously** (while the widget is still mounted) before
/// navigating away after a completion action.
void invalidatePlanProviders(WidgetRef ref, NavigationContext? navContext) {
  if (navContext == null) return;
  final planId = navContext.planId;
  final dayNumber = navContext.dayNumber;
  if (planId == null || dayNumber == null) return;

  ref.invalidate(
    userPlanDayContentFutureProvider(
      PlanDaysParams(planId: planId, dayNumber: dayNumber),
    ),
  );
  ref.invalidate(userPlanDaysCompletionStatusProvider(planId));
}
