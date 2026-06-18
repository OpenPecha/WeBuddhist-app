/// Recitation feature barrel export
///
/// Usage:
/// ```dart
/// import 'package:flutter_pecha/features/recitation/recitation.dart';
/// ```
library;

// Domain
export 'domain/content_type.dart';
export 'domain/recitation_language_config.dart';

// Domain - Entities
export 'domain/entities/recitation.dart';

// Domain - Repositories
export 'domain/repositories/recitation_repository.dart';

// Domain - Use Cases
export 'domain/usecases/recitation_usecases.dart';

// Models
export 'data/models/recitation_model.dart';
export 'data/models/recitation_content_model.dart';

// Data - Datasources
export 'data/datasource/recitations_remote_datasource.dart';

// Data - Repositories
export 'data/repositories/recitations_repository.dart';

// Presentation - Providers
export 'presentation/providers/recitations_providers.dart';
export 'presentation/providers/recitation_search_provider.dart';

// Presentation - Controllers
export 'presentation/controllers/recitation_save_controller.dart';

// Presentation - Screens
export 'presentation/screens/recitations_screen.dart';
export 'presentation/screens/recitation_detail_screen.dart';

// Presentation - Widgets
export 'presentation/widgets/recitation_card.dart';
export 'presentation/widgets/recitation_content.dart';
export 'presentation/widgets/recitation_segment.dart';
export 'presentation/widgets/recitation_text_section.dart';
export 'presentation/widgets/recitation_list_skeleton.dart';
export 'presentation/widgets/recitation_detail_skeleton.dart';
export 'presentation/widgets/recitation_error_state.dart';
export 'presentation/widgets/my_recitations_tab.dart';
export 'presentation/widgets/recitations_tab.dart';

// Presentation - Search
export 'presentation/search/recitation_search_delegate.dart';
