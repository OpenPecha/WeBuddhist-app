/// Auth feature barrel export
///
/// Exports all auth-related classes organized by layer.
/// Usage:
/// ```dart
/// import 'package:flutter_pecha/features/auth/auth.dart';
/// ```
library;

// Domain - Entities
export 'domain/entities/user.dart';

// Domain - Repositories
export 'domain/repositories/auth_repository.dart';

// Domain - Use Cases
export 'domain/usecases/get_current_user_usecase.dart';
export 'domain/usecases/logout_usecase.dart';

// Data - Models
export 'data/models/user_model.dart';

// Data - Repositories
export 'data/repositories/auth_repository_impl.dart';

// Data - Providers
export 'data/providers/auth_providers.dart';

// Application - Auth Service
export 'auth_service.dart';

// Application - Config
export 'application/config_service.dart';
export 'application/auth0_config.dart';

// Application - State
export 'application/auth_notifier.dart';
export 'application/user_notifier.dart';
export 'application/user_state.dart';

// Presentation - Screens
export 'presentation/login_page.dart';
export 'presentation/profile_page.dart';

// Presentation - Widgets
export 'presentation/widgets/auth_buttons.dart';
export 'presentation/widgets/login_drawer.dart';
export 'presentation/widgets/social_login_button.dart';
