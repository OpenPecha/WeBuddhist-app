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
export 'domain/entities/auth_credentials.dart';

// Domain - Repositories
export 'domain/repositories/auth_repository.dart';

// Domain - Use Cases
export 'domain/usecases/clear_guest_mode_and_onboarding_usecase.dart';
export 'domain/usecases/clear_guest_mode_usecase.dart';
export 'domain/usecases/continue_as_guest_usecase.dart';
export 'domain/usecases/get_credentials_usecase.dart';
export 'domain/usecases/get_current_user_usecase.dart';
export 'domain/usecases/get_valid_id_token_usecase.dart';
export 'domain/usecases/has_valid_credentials_usecase.dart';
export 'domain/usecases/initialize_auth_usecase.dart';
export 'domain/usecases/is_guest_mode_usecase.dart';
export 'domain/usecases/login_usecase.dart';
export 'domain/usecases/logout_usecase.dart';
export 'domain/usecases/refresh_id_token_usecase.dart';

// Data - Models
export 'data/models/user_model.dart';

// Data - Repositories
export 'data/repositories/auth_repository_impl.dart';

// Application - Auth Service
export 'auth_service.dart';

// Application - Config
export 'application/config_service.dart';
export 'application/auth0_config.dart';

// Presentation - State
export 'presentation/state/auth_state.dart';
export 'presentation/state/user_state.dart';

// Presentation - Providers
export 'presentation/providers/auth_providers.dart';
export 'presentation/providers/state_providers.dart';
export 'presentation/providers/use_case_providers.dart';

// Presentation - Notifiers
export 'presentation/providers/auth_notifier.dart';
export 'presentation/providers/user_notifier.dart';

// Presentation - Screens
export 'presentation/screens/login_page.dart';
export 'presentation/screens/profile_page.dart';

// Presentation - Widgets
export 'presentation/widgets/auth_buttons.dart';
export 'presentation/widgets/login_drawer.dart';
export 'presentation/widgets/social_login_button.dart';
