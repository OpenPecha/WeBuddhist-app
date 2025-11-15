import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/domain/recitation_language_config.dart';
import 'package:flutter_pecha/features/recitation/presentation/controllers/recitation_save_controller.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_content.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_error_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen that displays the detailed content of a recitation.
///
/// This screen:
/// - Loads recitation content based on user's language preference
/// - Allows authenticated users to save/unsave recitations
/// - Displays content in a language-appropriate order
/// - Handles loading and error states
class RecitationDetailScreen extends ConsumerWidget {
  final RecitationModel recitation;

  const RecitationDetailScreen({
    super.key,
    required this.recitation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get user's language preference
    final languageCode = ref.watch(localeProvider.select((locale) => locale.languageCode));

    // Check authentication status and saved state
    final isGuest = ref.watch(authProvider.select((state) => state.isGuest));
    final isSaved = _checkIfSaved(ref, isGuest);

    // Get content parameters and display order based on language
    final recitationParams = RecitationLanguageConfig.getContentParams(
      languageCode,
      recitation.textId,
    );
    final contentOrder = RecitationLanguageConfig.getContentOrder(languageCode);

    // Watch recitation content
    final contentAsync = ref.watch(recitationContentProvider(recitationParams));

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => _handleSaveToggle(context, ref, isSaved),
            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
            tooltip: isSaved ? 'Unsave recitation' : 'Save recitation',
          ),
        ],
      ),
      body: contentAsync.when(
        data: (content) => RecitationContent(
          content: content,
          contentOrder: contentOrder,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => RecitationErrorState(error: error),
      ),
    );
  }

  /// Checks if the current recitation is saved by the user.
  ///
  /// Returns false for guest users without checking the saved list.
  bool _checkIfSaved(WidgetRef ref, bool isGuest) {
    if (isGuest) return false;

    final savedRecitationsAsync = ref.watch(savedRecitationsFutureProvider);
    final savedRecitationIds =
        savedRecitationsAsync.valueOrNull?.map((e) => e.textId).toSet() ?? {};

    return savedRecitationIds.contains(recitation.textId);
  }

  /// Handles the save/unsave toggle action.
  void _handleSaveToggle(BuildContext context, WidgetRef ref, bool isSaved) {
    final controller = RecitationSaveController(
      ref: ref,
      context: context,
    );

    controller.toggleSave(
      textId: recitation.textId,
      isSaved: isSaved,
    );
  }
}
