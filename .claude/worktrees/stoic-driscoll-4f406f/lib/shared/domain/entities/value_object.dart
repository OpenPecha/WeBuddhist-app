import 'package:equatable/equatable.dart';

/// Base class for value objects.
///
/// Value objects are immutable objects whose identity is based on their
/// values rather than a unique identifier. They are used to ensure type
/// safety and encapsulate validation rules.
///
/// Example:
/// ```dart
/// class Email extends ValueObject {
///   final String value;
///
///   Email(this.value) {
///     if (!isValidEmail(value)) {
///       throw InvalidEmailException(value);
///     }
///   }
///
///   @override
///   List<Object?> get props => [value];
/// }
/// ```
abstract class ValueObject extends Equatable {
  const ValueObject();

  @override
  List<Object?> get props => [];
}
