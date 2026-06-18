/// AI feature barrel export
///
/// Usage:
/// ```dart
/// import 'package:flutter_pecha/features/ai/ai.dart';
/// ```
library;

// Domain - Entities
export 'domain/entities/chat_message.dart';
export 'domain/entities/chat_thread.dart';

// Domain - Repositories
export 'domain/repositories/ai_repository.dart' hide SearchResult;

// Domain - Use Cases
export 'domain/usecases/ai_usecases.dart';

// Config
export 'config/ai_config.dart';

// Models
export 'data/models/chat_message.dart' hide ChatMessage;
export 'data/models/chat_thread.dart';
export 'data/models/search_state.dart';

// Validators
export 'validators/message_validator.dart';

// Data - Datasources
export 'data/datasource/ai_chat_remote_datasource.dart';
export 'data/datasource/thread_remote_datasource.dart';
export 'data/datasource/segment_url_resolver_datasource.dart';

// Presentation - Providers
export 'presentation/providers/ai_chat_provider.dart';
export 'presentation/providers/segment_url_resolver_provider.dart';

// Data - Repositories
export 'data/repositories/ai_chat_repository.dart';
export 'data/repositories/segment_url_resolver_repository.dart';

// Services
export 'services/rate_limiter.dart';
export 'services/retry_service.dart';

// Presentation - Screens
export 'presentation/screens/ai_mode_screen.dart';
export 'presentation/screens/search_results_screen.dart';

// Presentation - Controllers
export 'presentation/controllers/chat_controller.dart';
export 'presentation/controllers/search_state_controller.dart';
export 'presentation/controllers/thread_list_controller.dart';

// Presentation - Widgets
export 'presentation/widgets/message_list.dart';
export 'presentation/widgets/message_bubble.dart';
export 'presentation/widgets/thread_list_item.dart';
export 'presentation/widgets/chat_header.dart';
export 'presentation/widgets/chat_history_drawer.dart';
export 'presentation/widgets/all_tab_view.dart';
export 'presentation/widgets/author_tab_view.dart';
export 'presentation/widgets/contents_tab_view.dart';
export 'presentation/widgets/titles_tab_view.dart';
export 'presentation/widgets/typing_indicator.dart';
export 'presentation/widgets/delete_thread_dialog.dart';
export 'presentation/widgets/source_bottom_sheet.dart';
export 'presentation/widgets/skeletons/chat_message_skeleton.dart';
export 'presentation/widgets/skeletons/chat_thread_skeleton.dart';
export 'presentation/widgets/skeletons/search_result_skeleton.dart';
