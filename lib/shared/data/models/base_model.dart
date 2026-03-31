import 'package:flutter_pecha/shared/domain/entities/base_entity.dart';

/// Base class for data models.
///
/// Models are responsible for data serialization/deserialization and
/// conversion to/from domain entities. They belong to the data layer.
abstract class BaseModel<T extends BaseEntity> {
  /// Convert this model to a domain entity
  T toEntity();

  /// Convert this model to JSON for API requests or storage
  Map<String, dynamic> toJson();

  /// Create a model instance from JSON
  factory BaseModel.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson must be implemented');
  }
}
