/// Shared layer barrel export
///
/// This file exports all shared utilities, base classes, and widgets
/// that are used across multiple features.
///
/// Usage:
/// ```dart
/// import 'package:flutter_pecha/shared/shared.dart';
/// ```
library;

// Domain - Base Classes
export 'domain/base_classes/datasource.dart';
export 'domain/base_classes/repository.dart';
export 'domain/base_classes/usecase.dart';

// Domain - Entities
export 'domain/entities/base_entity.dart';
export 'domain/entities/value_object.dart';

// Domain - Value Objects
export 'domain/value_objects/email.dart';
export 'domain/value_objects/unique_id.dart';
export 'domain/value_objects/pagination_params.dart';
export 'domain/value_objects/date_range.dart';

// Data
export 'data/models/base_model.dart';

// Presentation
export 'presentation/providers/base_state.dart';
