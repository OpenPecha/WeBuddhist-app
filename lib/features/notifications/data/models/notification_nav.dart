import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationNav {
  final String itemId;
  final String itemType;

  /// Active plan id for series notifications (opens today's plan day).
  final String? planId;

  const NotificationNav({
    required this.itemId,
    required this.itemType,
    this.planId,
  });
}

/// Stores a pending deep-link from a notification tap.
/// Set by NotificationService; consumed and cleared by RoutineFilledState.
final pendingNotificationNavProvider = StateProvider<NotificationNav?>((ref) => null);
