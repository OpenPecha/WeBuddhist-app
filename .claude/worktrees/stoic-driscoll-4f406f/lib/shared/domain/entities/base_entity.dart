import 'package:equatable/equatable.dart';

/// Base class for all domain entities.
///
/// Entities are pure domain objects that represent business concepts.
/// They should not contain any framework-specific code or JSON serialization.
/// Use Equatable for value equality comparison.
abstract class BaseEntity extends Equatable {
  const BaseEntity();

  @override
  List<Object?> get props => [];
}
