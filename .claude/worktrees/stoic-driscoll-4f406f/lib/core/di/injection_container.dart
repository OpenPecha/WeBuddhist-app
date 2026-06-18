/// Dependency Injection Container
///
/// This file serves as the central registry for all app dependencies.
/// Core providers are exported from core_providers.dart, and feature-specific
/// providers should be imported from their respective feature modules.
///
/// Usage:
/// ```dart
/// import 'package:flutter_pecha/core/di/injection_container.dart';
/// import 'package:flutter_pecha/features/auth/auth.dart';
///
/// // Use providers in your widgets
/// final dioClient = ref.watch(dioClientProvider);
/// ```
library;

export 'core_providers.dart';
