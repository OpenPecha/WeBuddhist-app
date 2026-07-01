import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationNav {
  final String itemId;
  final String itemType;

  /// Active plan id for series notifications (opens today's plan day).
  final String? planId;

  /// Timer duration (ms) embedded in the notification payload, so a timer tap
  /// can open the timer without re-resolving the (possibly stale or not-yet-
  /// loaded) routine item. Null for non-timer notifications.
  final int? durationMs;

  /// The timer block's scheduled time-of-day as minutes past midnight
  /// (`hour * 60 + minute`). The timer screen anchors to the most recent
  /// occurrence of this time and syncs its remaining time from the wall clock.
  /// Null for non-timer notifications.
  final int? startMinuteOfDay;

  const NotificationNav({
    required this.itemId,
    required this.itemType,
    this.planId,
    this.durationMs,
    this.startMinuteOfDay,
  });
}

/// Stores a pending deep-link from a notification tap.
/// Set by NotificationService; consumed and cleared by RoutineFilledState.
final pendingNotificationNavProvider = StateProvider<NotificationNav?>((ref) => null);
