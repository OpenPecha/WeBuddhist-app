/// Core layer barrel export
///
/// This file exports all core utilities, services, and configurations
/// that are used throughout the app.
///
/// Usage:
/// ```dart
/// import 'package:flutter_pecha/core/core.dart';
/// import 'package:flutter_pecha/env.dart';
/// ```
library;

// Config
export 'config/api_config.dart';
export 'config/router/app_router.dart';
export 'config/router/app_routes.dart';
export 'config/router/route_guard.dart';
export 'config/router/route_config.dart';

// Constants
export 'constants/app_config.dart';
export 'constants/app_assets.dart';
// Storage keys are now exported from storage/storage_keys.dart

// Error
export 'error/exceptions.dart';
export 'error/failures.dart';
export 'error/error_message_mapper.dart';

// Network - hide providers to use the ones from DI instead
export 'network/connectivity_service.dart' hide connectivityServiceProvider, isOnlineProvider, connectivityStreamProvider, connectivityNotifierProvider;
export 'network/dio_client.dart';
export 'network/network_info.dart';
export 'network/interceptors/interceptors.dart';

// Cache - hide CacheException to avoid ambiguity with error/exceptions.dart
export 'cache/cache_service.dart';
export 'cache/cache_config.dart';
export 'cache/cache_entry.dart' hide CacheException;

// Storage - hide storageServiceProvider to use the one from DI instead
export 'storage/preferences_service.dart' hide storageServiceProvider;
export 'storage/secure_storage_impl.dart';
export 'storage/storage_service.dart';
export 'storage/storage_keys.dart';

// Utils
export 'utils/app_logger.dart';

// DI
export 'di/di.dart';

// Theme
export 'theme/app_theme.dart';

// Widgets
export 'widgets/error_state_widget.dart';
export 'widgets/skeletons/skeletons.dart';
