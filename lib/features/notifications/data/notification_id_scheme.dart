import 'package:flutter_pecha/features/notifications/data/special_plan_notifications.dart';

/// Central registry for every notification ID range the app owns.
///
/// The reconciliation engine uses [isOurs] to scope cancellation: it must
/// never cancel an ID that doesn't belong to this app. Each scheme below
/// matches the constants that previously lived inline in
/// `routine_notification_service.dart` and `RoutineBlock.notificationId`.
class NotificationIdScheme {
  NotificationIdScheme._();

  /// Diagnostic test notification ID (mirrors the constant used by
  /// [`notification_settings_screen.dart`]).
  static const int kDiagnosticTestId = 9999;

  // Special-plan immediate one-shots: 800 + (dayIndex - 1) → 800–807 for 8 days.
  static const int specialPlanOneShotBase = 800;
  static const int specialPlanOneShotMax = 899;

  // Special-plan daily series: 810 + slot*10 + (day-1).
  static const int specialPlanSeriesBase = 810;
  static const int specialPlanSeriesSlot = 10;

  // Routine block hash (FNV-1a in [RoutineBlock.notificationId]).
  static const int routineBlockMin = 1000;
  static const int routineBlockMax = 999999;

  // General-plan immediate one-shot.
  static const int planOneShotBase = 9000000;
  static const int planOneShotMax = 9009999;

  // General-plan daily series.
  static const int planSeriesBase = 10000000;
  static const int planSeriesSlot = 500;
  static const int planSeriesMax = 15004999;

  // Routine block accumulator (mala) daily-repeat. A block may hold both a
  // recitation and a mala; the recitation keeps [RoutineBlock.notificationId]
  // (routineBlock* range) while the mala maps into this parallel range so the
  // two daily-repeats never collide on one ID.
  static const int accumulatorBlockBase = 20000000;
  static const int accumulatorBlockMax = 20999999;

  // Routine block timer daily-repeats. A timer block fires TWO daily reminders
  // — one at block time ("timer started") and one at block time + duration
  // ("timer up") — each in its own parallel range so they never collide with
  // the recitation/mala daily-repeats a block may also hold.
  static const int timerStartBase = 21000000;
  static const int timerStartMax = 21999999;
  static const int timerEndBase = 22000000;
  static const int timerEndMax = 22999999;

  /// ID for the [day]th notification of [planId]'s special-plan series.
  /// Throws if [planId] is not a registered special plan.
  static int specialPlanSeriesId(String planId, int day) {
    final slot = kSpecialPlanNotifications.keys.toList().indexOf(planId);
    if (slot < 0) throw ArgumentError('$planId is not a special plan');
    return specialPlanSeriesBase + (slot * specialPlanSeriesSlot) + (day - 1);
  }

  /// ID for the immediate one-shot for day [dayIndex] of a special plan.
  static int specialPlanOneShotId(int dayIndex) =>
      specialPlanOneShotBase + (dayIndex - 1);

  /// ID for the [day]th notification of a general plan's duration series.
  static int planSeriesId(String planId, int day) {
    final slot = planId.hashCode.abs() % 10000;
    return planSeriesBase + (slot * planSeriesSlot) + (day - 1);
  }

  /// ID for a general plan's immediate one-shot.
  static int planOneShotId(String planId) =>
      planOneShotBase + planId.hashCode.abs() % 10000;

  /// Stable daily-repeat ID for a mala/accumulator block. Derived from the
  /// block's own notification ID so it survives restarts, but lives in a
  /// range separate from the recitation daily-repeat
  /// ([RoutineBlock.notificationId]) so a block holding both never collides.
  static int accumulatorBlockId(int blockNotificationId) =>
      accumulatorBlockBase + (blockNotificationId - routineBlockMin);

  /// Stable daily-repeat ID for a timer block's "started" reminder, fired at
  /// block time. Derived from the block's own notification ID (like
  /// [accumulatorBlockId]) but in a separate range so a block holding a timer
  /// plus other item types never collides.
  static int timerStartId(int blockNotificationId) =>
      timerStartBase + (blockNotificationId - routineBlockMin);

  /// Stable daily-repeat ID for a timer block's "timer up" reminder, fired at
  /// block time + duration. Parallel range to [timerStartId].
  static int timerEndId(int blockNotificationId) =>
      timerEndBase + (blockNotificationId - routineBlockMin);

  /// True when [id] is a routine daily-repeat: recitation/chants via
  /// [routineBlockMin]–[routineBlockMax], mala via the accumulator range, or a
  /// timer start/end reminder via the timer ranges.
  ///
  /// These are computed purely from the routine blocks + toggles and never
  /// depend on plan-enrollment state, so the engine may reconcile (cancel)
  /// them even while the plans list is unresolved — unlike plan-derived IDs,
  /// which stay in additive-only mode until enrollment is known.
  static bool isRoutineDailyRepeat(int id) =>
      (id >= routineBlockMin && id <= routineBlockMax) ||
      (id >= accumulatorBlockBase && id <= accumulatorBlockMax) ||
      (id >= timerStartBase && id <= timerEndMax);

  /// True when [id] was issued by any of the schemes registered here.
  /// Used by the engine to scope reconciliation: it must NEVER cancel an
  /// ID that doesn't belong to this app (e.g. another plugin's IDs).
  static bool isOurs(int id) {
    if (id == kDiagnosticTestId) return true;
    if (id >= specialPlanOneShotBase && id <= specialPlanOneShotMax) return true;
    if (id >= routineBlockMin && id <= routineBlockMax) return true;
    if (id >= planOneShotBase && id <= planOneShotMax) return true;
    if (id >= planSeriesBase && id <= planSeriesMax) return true;
    if (id >= accumulatorBlockBase && id <= accumulatorBlockMax) return true;
    if (id >= timerStartBase && id <= timerEndMax) return true;
    return false;
  }
}
