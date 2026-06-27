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

  /// True when [id] was issued by any of the schemes registered here.
  /// Used by the engine to scope reconciliation: it must NEVER cancel an
  /// ID that doesn't belong to this app (e.g. another plugin's IDs).
  static bool isOurs(int id) {
    if (id == kDiagnosticTestId) return true;
    if (id >= specialPlanOneShotBase && id <= specialPlanOneShotMax)
      return true;
    if (id >= routineBlockMin && id <= routineBlockMax) return true;
    if (id >= planOneShotBase && id <= planOneShotMax) return true;
    if (id >= planSeriesBase && id <= planSeriesMax) return true;
    return false;
  }
}
