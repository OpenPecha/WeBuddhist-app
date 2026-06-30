import 'package:equatable/equatable.dart';

/// A push message delivered by Firebase Cloud Messaging.
///
/// Pure domain entity — free of any Firebase / Flutter SDK types. The data
/// layer maps the platform `RemoteMessage` into this shape.
class PushMessage extends Equatable {
  /// Notification title (null for data-only messages).
  final String? title;

  /// Notification body (null for data-only messages).
  final String? body;

  /// Arbitrary key/value payload used for routing and custom handling.
  final Map<String, dynamic> data;

  const PushMessage({
    this.title,
    this.body,
    this.data = const {},
  });

  /// Whether the message carries a user-visible notification block.
  bool get hasNotification => (title?.isNotEmpty ?? false) || (body?.isNotEmpty ?? false);

  @override
  List<Object?> get props => [title, body, data];
}
