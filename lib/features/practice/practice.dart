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

// Domain - Repositories
export 'domain/repositories/practice_repository.dart';

// Domain - Use Cases
export 'domain/usecases/get_routines_usecase.dart';
export 'domain/usecases/start_practice_usecase.dart';
export 'domain/usecases/complete_practice_usecase.dart';

// Data - Models
export 'data/models/routine_model.dart';
export 'data/models/session_selection.dart';

// Data - Services
export 'data/services/routine_notification_service.dart';

// Data - Providers
export 'data/providers/routine_provider.dart';

// Data - Utils
export 'data/utils/routine_time_utils.dart';

// Data - Datasources
export 'data/datasources/routine_local_storage.dart';

// Presentation - Screens
export 'presentation/screens/practice_screen.dart';
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
