/// Onboarding feature barrel export
///
/// Usage:
/// ```dart
/// import 'package:flutter_pecha/features/onboarding/onboarding.dart';
/// ```
library;

// Domain - Entities
export 'domain/entities/onboarding_preferences.dart';

// Domain - Repositories
export 'domain/repositories/onboarding_repository.dart';

// Domain - Use Cases
export 'domain/usecases/onboarding_usecases.dart';

// Data - Models
export 'data/models/onboarding_preferences.dart' hide OnboardingPreferences;

// Application
export 'application/onboarding_notifier.dart';
export 'application/onboarding_state.dart';
export 'application/onboarding_provider.dart';

// Data - Repositories
export 'data/repositories/onboarding_repository.dart' hide OnboardingRepository;

// Data - Datasources
export 'data/onboarding_local_datasource.dart';
export 'data/onboarding_remote_datasource.dart';

// Presentation - Providers
export 'presentation/providers/onboarding_datasource_providers.dart';

// Presentation - Screens
export 'presentation/onboarding_wrapper.dart';
export 'presentation/onboarding_screen_1.dart';
export 'presentation/onboarding_screen_3.dart';
export 'presentation/onboarding_screen_5.dart';

// Presentation - Widgets
export 'presentation/widgets/onboarding_back_button.dart';
export 'presentation/widgets/onboarding_continue_button.dart';
export 'presentation/widgets/onboarding_radio_option.dart';
export 'presentation/widgets/onboarding_question_title.dart';
