import 'package:flutter_pecha/shared/domain/entities/value_object.dart';

/// Email value object.
///
/// Ensures email validity at creation time.
class Email extends ValueObject {
  final String value;

  const Email._(this.value);

  /// Create an Email instance. Returns null if invalid.
  static Email? create(String input) {
    if (isValid(input)) {
      return Email._(input.trim().toLowerCase());
    }
    return null;
  }

  /// Create an Email or throw an exception.
  factory Email.fromString(String input) {
    final email = create(input);
    if (email == null) {
      throw ArgumentError('Invalid email address: $input');
    }
    return email;
  }

  /// Validate email format.
  static bool isValid(String email) {
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return regex.hasMatch(email.trim());
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
