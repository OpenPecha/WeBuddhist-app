/// Practice feature barrel export
///
/// Usage:
/// ```dart
/// import 'package:flutter_pecha/features/practice/practice.dart';
/// ```
library;

// Domain - Entities
export 'domain/entities/routine.dart';
export 'domain/entities/practice_session.dart';
export 'domain/entities/practice_progress.dart';
export 'domain/entities/practice_item.dart';
export 'domain/entities/practice_items_page.dart';
export 'domain/entities/practice_items_tab.dart';

// Domain - Repositories
export 'domain/repositories/practice_repository.dart';
export 'domain/repositories/routine_api_repository.dart';
export 'domain/repositories/practice_items_repository.dart';

// Domain - Use Cases (local storage)
export 'domain/usecases/get_routines_usecase.dart';
export 'domain/usecases/start_practice_usecase.dart';
export 'domain/usecases/complete_practice_usecase.dart';

// Domain - Use Cases (remote API)
export 'domain/usecases/routine_api_usecases.dart';
export 'domain/usecases/get_practice_items_usecase.dart';

// Data - Models
export 'data/models/routine_model.dart';
export 'data/models/routine_api_models.dart';
export 'data/models/session_selection.dart';
export 'data/models/practice_item_model.dart';

// Data - Services
export 'package:flutter_pecha/features/notifications/data/services/routine_notification_service.dart';

// Data - Utils
export 'data/utils/routine_time_utils.dart';
export 'data/utils/routine_api_mapper.dart';

// Data - Datasources
export 'data/datasource/routine_local_storage.dart';
export 'data/datasource/practice_items_remote_datasource.dart';

// Presentation - Providers
export 'presentation/providers/practice_providers.dart';
export 'presentation/providers/use_case_providers.dart';
export 'presentation/providers/routine_api_providers.dart';
export 'presentation/providers/routine_provider.dart';
export 'presentation/providers/practice_items_paginated_provider.dart';
export 'presentation/providers/practice_explore_providers.dart';

// Presentation - Screens
export 'presentation/screens/practice_screen.dart';
export 'presentation/screens/practice_explore_screen.dart';
export 'presentation/screens/select_session_screen.dart';
export 'presentation/screens/select_plan_screen.dart';
export 'presentation/screens/select_recitation_screen.dart';
export 'presentation/screens/edit_routine_screen.dart';

// Presentation - Widgets
export 'presentation/widgets/routine_item_card.dart';
export 'presentation/widgets/routine_empty_state.dart';
export 'presentation/widgets/routine_action_button.dart';
export 'presentation/widgets/routine_filled_state.dart';
export 'presentation/widgets/routine_time_block.dart';
