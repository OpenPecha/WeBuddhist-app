# WeBuddhist - Complete Project Structure

> Generated documentation of the Clean Architecture implementation

---

## Directory Structure

```
lib/
├── main.dart                           # App entry point
├── env.dart                            # Environment configuration
│
├── core/                               # CORE LAYER - Infrastructure
│   ├── config/
│   │   ├── api_config.dart             # API base URL, timeouts
│   │   ├── app_feature_flags.dart      # Feature toggles
│   │   ├── locale/
│   │   │   └── locale_notifier.dart    # Locale state management
│   │   └── router/
│   │       ├── app_router.dart          # GoRouter configuration
│   │       ├── app_routes.dart          # Route definitions
│   │       ├── route_guard.dart         # Auth guard implementation
│   │       ├── route_config.dart        # Route configuration
│   │       └── go_router.dart           # GoRouter setup
│   │
│   ├── network/
│   │   ├── dio_client.dart              # Dio HTTP client with interceptors
│   │   ├── network_info.dart            # Network connectivity interface
│   │   ├── connectivity_service.dart    # Connectivity implementation
│   │   ├── api_client_provider.dart     # Legacy HTTP client provider
│   │   ├── mock/
│   │   │   └── mock_dio_client.dart     # Mock for testing
│   │   └── interceptors/
│   │       ├── interceptors.dart        # Barrel export
│   │       ├── auth_interceptor.dart    # Add auth tokens
│   │       ├── cache_interceptor.dart   # Cache GET requests
│   │       ├── error_interceptor.dart   # Convert errors to exceptions
│   │       ├── logging_interceptor.dart # Log all requests
│   │       └── retry_interceptor.dart   # Retry failed requests
│   │
│   ├── storage/
│   │   ├── storage_service.dart         # Storage interface
│   │   ├── secure_storage_impl.dart     # FlutterSecureStorage impl
│   │   ├── preferences_service.dart     # SharedPreferences impl
│   │   ├── storage_keys.dart            # Single source of truth for keys
│   │   ├── mock_storage_service.dart    # Mock for testing
│   │   └── mock_secure_storage.dart     # Mock for testing
│   │
│   ├── cache/
│   │   ├── cache_service.dart           # Cache interface
│   │   ├── cache_config.dart            # Cache configuration
│   │   ├── cache_entry.dart             # Cache entry model
│   │   ├── cache.dart                   # Cache utilities
│   │   └── cache_provider.dart          # Cache state provider
│   │
│   ├── error/
│   │   ├── exceptions.dart              # Exception classes
│   │   ├── failures.dart                # Failure types (Either<Failure, T>)
│   │   └── error_message_mapper.dart    # Centralized error messages
│   │
│   ├── di/
│   │   ├── injection_container.dart     # DI container
│   │   ├── core_providers.dart          # Core service providers
│   │   └── di.dart                      # Barrel export
│   │
│   ├── theme/
│   │   ├── app_theme.dart               # App theming
│   │   ├── app_colors.dart              # Color definitions
│   │   ├── font_config.dart             # Font configuration
│   │   └── theme_notifier.dart          # Theme state management
│   │
│   ├── utils/
│   │   ├── app_logger.dart              # Logging utility
│   │   ├── error_message_mapper.dart    # Legacy error mapper
│   │   ├── get_language.dart            # Language utility
│   │   └── local_storage_service.dart   # Local storage utility
│   │
│   ├── services/
│   │   ├── service_providers.dart       # Service providers
│   │   ├── audio/
│   │   │   └── audio_handler.dart       # Audio playback handler
│   │   ├── background_image/
│   │   │   ├── background_image_service.dart
│   │   │   └── background_image_constants.dart
│   │   ├── app_share/
│   │   │   ├── app_share_service.dart
│   │   │   ├── app_share.dart
│   │   │   └── qr_code_bottom_sheet.dart
│   │   └── upgrade/
│   │       ├── app_upgrade_wrapper.dart
│   │       └── app_upgrade_config.dart
│   │
│   ├── widgets/
│   │   ├── cached_network_image_widget.dart
│   │   ├── audio_controls.dart
│   │   ├── audio_progress_bar.dart
│   │   ├── logo_label.dart
│   │   ├── error_state_widget.dart
│   │   └── skeletons/
│   │       ├── skeletons.dart
│   │       ├── tag_grid_skeleton.dart
│   │       ├── plan_preview_skeleton.dart
│   │       └── plan_list_skeleton.dart
│   │
│   ├── localization/
│   │   ├── material_localizations_bo.dart
│   │   └── cupertino_localizations_bo.dart
│   │
│   ├── l10n/
│   │   ├── l10n.dart                    # Localization setup
│   │   └── generated/                   # Generated localization files
│   │
│   ├── constants/
│   │   ├── app_config.dart              # App constants
│   │   ├── app_assets.dart              # Asset paths
│   │   └── app_storage_keys.dart        # (Deprecated, use storage/storage_keys.dart)
│   │
│   ├── extensions/
│   │   └── context_ext.dart             # BuildContext extensions
│   │
│   └── core.dart                        # Barrel export
│
├── shared/                             # SHARED LAYER - Cross-feature code
│   ├── domain/
│   │   ├── base_classes/
│   │   │   ├── usecase.dart             # UseCase<Type, Params> base class
│   │   │   ├── repository.dart          # Repository base class
│   │   │   └── datasource.dart          # Datasource base classes
│   │   ├── entities/
│   │   │   ├── base_entity.dart         # BaseEntity with Equatable
│   │   │   └── value_object.dart        # ValueObject base class
│   │   └── value_objects/
│   │       ├── email.dart               # Email value object with validation
│   │       ├── unique_id.dart           # UUID wrapper
│   │       ├── pagination_params.dart   # Pagination configuration
│   │       └── date_range.dart          # Date range with validation
│   │
│   ├── data/
│   │   └── models/
│   │       └── base_model.dart          # BaseModel<T extends BaseEntity>
│   │
│   ├── presentation/
│   │   └── providers/
│   │       └── base_state.dart          # BaseState, LoadedState, ErrorState
│   │
│   ├── utils/
│   │   └── helper_functions.dart        # Shared utility functions
│   │
│   ├── extensions/
│   │   └── typography_extensions.dart    # Typography extensions
│   │
│   └── shared.dart                      # Barrel export
│
└── features/                           # FEATURE MODULES
    │
    ├── auth/                            # AUTHENTICATION
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── user.dart            # User entity
    │   │   ├── repositories/
    │   │   │   └── auth_repository.dart # AuthRepository interface
    │   │   └── usecases/
    │   │       ├── get_current_user_usecase.dart
    │   │       └── logout_usecase.dart
    │   ├── data/                         # Data layer implementation
    │   ├── presentation/                 # UI layer
    │   ├── auth_service.dart             # Legacy auth service
    │   └── auth.dart                     # Barrel export
    │
    ├── reader/                          # TEXT READER
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── text_content.dart    # TextContent, Section, Verse entities
    │   │   ├── repositories/
    │   │   │   └── reader_repository.dart
    │   │   ├── usecases/
    │   │   │   ├── load_initial_text_usecase.dart
    │   │   │   ├── load_next_page_usecase.dart
    │   │   │   └── navigate_to_section_usecase.dart
    │   │   └── services/
    │   │       ├── navigation_service.dart
    │   │       ├── section_merger_service.dart
    │   │       └── section_flattener_service.dart
    │   ├── data/
    │   │   ├── models/
    │   │   ├── providers/
    │   │   └── repositories/
    │   ├── presentation/
    │   │   ├── reader_screen.dart
    │   │   └── widgets/
    │   ├── constants/
    │   └── reader.dart                  # Barrel export
    │
    ├── practice/                        # PRACTICE TRACKING
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   ├── routine.dart         # Routine entity
    │   │   │   ├── practice_session.dart
    │   │   │   └── practice_progress.dart
    │   │   ├── repositories/
    │   │   │   └── practice_repository.dart
    │   │   └── usecases/
    │   │       ├── get_routines_usecase.dart
    │   │       ├── start_practice_usecase.dart
    │   │       └── complete_practice_usecase.dart
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   └── routine_local_storage.dart
    │   │   └── providers/
    │   │       └── routine_provider.dart
    │   ├── presentation/
    │   └── practice.dart                # Barrel export
    │
    ├── plans/                           # PRACTICE PLANS
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   ├── plan.dart            # Plan entity with WeekPlan list
    │   │   │   ├── week_plan.dart       # WeekPlan entity
    │   │   │   ├── plan_day.dart        # PlanDay entity
    │   │   │   ├── plan_task.dart       # PlanTask entity
    │   │   │   ├── plan_progress.dart   # PlanProgress entity
    │   │   │   └── author.dart          # Author entity
    │   │   ├── repositories/
    │   │   │   └── plans_repository.dart
    │   │   └── usecases/
    │   │       └── plans_usecases.dart  # GetPlans, GetPlanDetail, etc.
    │   ├── data/
    │   ├── presentation/
    │   └── plans.dart                   # Barrel export
    │
    ├── ai/                              # AI FEATURES
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   ├── chat_message.dart    # ChatMessage entity
    │   │   │   └── chat_thread.dart     # ChatThread entity
    │   │   ├── repositories/
    │   │   │   └── ai_repository.dart
    │   │   └── usecases/
    │   │       └── ai_usecases.dart     # SearchText, AskQuestion, etc.
    │   ├── config/
    │   │   └── ai_config.dart           # AI configuration
    │   ├── data/
    │   │   ├── datasource/
    │   │   ├── models/
    │   │   ├── providers/
    │   │   └── repositories/
    │   ├── services/
    │   │   ├── rate_limiter.dart
    │   │   └── retry_service.dart
    │   ├── presentation/
    │   │   ├── ai_mode_screen.dart
    │   │   ├── search_results_screen.dart
    │   │   ├── controllers/
    │   │   └── widgets/
    │   ├── validators/
    │   │   └── message_validator.dart
    │   └── ai.dart                      # Barrel export
    │
    ├── texts/                           # TEXT LIBRARY
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   ├── text.dart            # TextEntity (renamed to avoid conflict)
    │   │   │   ├── section.dart         # SectionEntity
    │   │   │   ├── segment.dart         # SegmentEntity
    │   │   │   └── version.dart         # VersionEntity
    │   │   ├── repositories/
    │   │   │   └── texts_repository.dart
    │   │   └── usecases/
    │   │       └── texts_usecases.dart  # GetTexts, GetTextDetail, SearchTexts
    │   ├── data/
    │   │   ├── datasource/
    │   │   ├── models/
    │   │   ├── providers/
    │   │   └── repositories/
    │   ├── presentation/
    │   │   ├── screens/
    │   │   ├── widgets/
    │   │   └── commentary/
    │   ├── constants/
    │   ├── utils/
    │   └── texts.dart                   # Barrel export
    │
    ├── recitation/                      # AUDIO RECITATION
    │   ├── domain/
    │   │   ├── content_type.dart        # ContentType enum
    │   │   ├── recitation_language_config.dart
    │   │   ├── entities/
    │   │   │   └── recitation.dart     # Recitation entity
    │   │   ├── repositories/
    │   │   │   └── recitation_repository.dart
    │   │   └── usecases/
    │   │       └── recitation_usecases.dart
    │   ├── data/
    │   ├── presentation/
    │   └── recitation.dart              # Barrel export
    │
    ├── home/                            # HOME SCREEN
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   ├── prayer.dart          # Prayer entity
    │   │   │   ├── featured_content.dart
    │   │   │   └── daily_quote.dart
    │   │   ├── repositories/
    │   │   │   └── home_repository.dart
    │   │   └── usecases/
    │   │       └── home_usecases.dart   # GetFeaturedContent, etc.
    │   ├── data/
    │   ├── presentation/
    │   └── home.dart                    # Barrel export
    │
    ├── story_view/                      # STORY VIEW
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── story.dart           # Story, StorySlide entities
    │   │   ├── repositories/
    │   │   │   └── story_view_repository.dart
    │   │   └── usecases/
    │   │       └── story_view_usecases.dart
    │   ├── data/
    │   ├── presentation/
    │   │   ├── screens/
    │   │   ├── widgets/
    │   │   └── story_presenter/
    │   ├── services/
    │   │   └── story_media_preloader.dart
    │   ├── utils/
    │   └── story_view.dart              # Barrel export
    │
    ├── notifications/                   # PUSH NOTIFICATIONS
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   ├── notification.dart    # AppNotification entity
    │   │   │   └── notification_settings.dart
    │   │   ├── repositories/
    │   │   │   └── notifications_repository.dart
    │   │   └── usecases/
    │   │       └── notifications_usecases.dart
    │   ├── data/
    │   ├── presentation/
    │   ├── services/
    │   │   └── notification_service.dart
    │   └── notifications.dart           # Barrel export
    │
    ├── onboarding/                      # ONBOARDING FLOW
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   ├── onboarding_preferences.dart
    │   │   │   ├── onboarding_step.dart
    │   │   │   └── onboarding_option.dart
    │   │   ├── repositories/
    │   │   │   └── onboarding_repository.dart
    │   │   └── usecases/
    │   │       └── onboarding_usecases.dart
    │   ├── data/
    │   ├── presentation/
    │   └── onboarding.dart              # Barrel export
    │
    ├── app/                             # APP-LEVEL WIDGETS
    │   └── ...
    ├── creator_info/                    # CREATOR INFO FEATURE
    │   └── ...
    ├── meditation_of_day/               # MEDITATION OF DAY
    │   └── ...
    ├── more/                            # MORE SCREEN
    │   └── ...
    ├── prayer_of_the_day/               # PRAYER OF THE DAY
    │   └── ...
```

---

## File Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Entities | `lowercase.dart` | `user.dart`, `text_content.dart` |
| Repositories | `feature_repository.dart` | `auth_repository.dart` |
| Use Cases | `action_usecase.dart` | `get_current_user_usecase.dart` |
| Models | `lowercase.dart` | `user_model.dart` |
| Screens | `feature_screen.dart` | `login_screen.dart` |
| Widgets | `lowercase.dart` | `error_widget.dart` |

---

## Import Patterns

### Preferred (Barrel Exports)

```dart
import 'package:flutter_pecha/core/core.dart';
import 'package:flutter_pecha/shared/shared.dart';
import 'package:flutter_pecha/features/auth/auth.dart';
```

### Avoid (Relative Imports)

```dart
// Don't do this
import '../../../../core/error/failures.dart';
import '../domain/entities/user.dart';
```

---

## Layer Dependencies

```
Presentation ──depends on──> Domain
Data ──depends on──> Domain
Domain ──depends on──> Shared
Data ──depends on──> Core
Presentation ──depends on──> Core
```

**Key Rule:** Domain layer NEVER depends on Data, Presentation, or any Flutter framework.

---

*Generated for WeBuddhist App - Clean Architecture Implementation*
