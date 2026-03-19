/// Notifications feature barrel export
///
/// Usage:
/// ```dart
/// import 'package:flutter_pecha/features/notifications/notifications.dart';
/// ```
library;

// Domain - Entities
export 'domain/entities/notification.dart';
export 'domain/entities/notification_settings.dart';

// Domain - Repositories
export 'domain/repositories/notifications_repository.dart';

// Domain - Use Cases
export 'domain/usecases/notifications_usecases.dart';

// Provider
export 'provider/notification_provider.dart';

// Services
export 'services/notification_service.dart';

// Presentation
export 'presentation/notification_settings_screen.dart';
