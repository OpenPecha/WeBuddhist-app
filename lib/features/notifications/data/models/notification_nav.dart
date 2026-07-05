import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationNav {
  final String itemId;
  final String itemType;

  /// Active plan id for series notifications (opens today's plan day).
  final String? planId;

  /// When non-null, navigating to a plan opens this specific day instead of
  /// computing today's day from the start date. Used by plan-day deep links
  /// so the recipient lands on the exact day that was shared.
  final int? dayNumber;

  /// Timer duration (ms) embedded in the notification payload, so a timer tap
  /// can open the timer without re-resolving the (possibly stale or not-yet-
  /// loaded) routine item. Null for non-timer notifications.
  final int? durationMs;

  const NotificationNav({
    required this.itemId,
    required this.itemType,
    this.planId,
    this.dayNumber,
    this.durationMs,
  });
}

/// Stores a pending deep-link from a notification tap.
/// Set by NotificationService; consumed and cleared by RoutineFilledState.
final pendingNotificationNavProvider = StateProvider<NotificationNav?>((ref) => null);
