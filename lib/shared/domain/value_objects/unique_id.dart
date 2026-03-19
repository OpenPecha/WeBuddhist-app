import 'package:flutter_pecha/shared/domain/entities/value_object.dart';
import 'package:uuid/uuid.dart';

/// Unique identifier value object.
///
/// Wraps a UUID string to ensure type safety.
class UniqueId extends ValueObject {
  final String value;

  const UniqueId._(this.value);

  /// Create a new unique ID.
  factory UniqueId() {
    return UniqueId._(const Uuid().v4());
  }

  /// Create from an existing string.
  factory UniqueId.fromString(String id) {
    if (id.isEmpty) {
      throw ArgumentError('ID cannot be empty');
    }
    return UniqueId._(id);
  }

  /// Create a new UniqueId or return null if input is empty.
  static UniqueId? create(String? input) {
    if (input == null || input.isEmpty) return null;
    return UniqueId.fromString(input);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
