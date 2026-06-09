import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReaderMetadataSubtitle extends ConsumerWidget {
  const ReaderMetadataSubtitle({super.key, required this.params});

  final ReaderParams params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readerNotifierProvider(params));
    final settings = ref.watch(readerDualSettingsProvider(params.textId));
    if (state.textDetail == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final text = _composeLabel(context, settings, state);

    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 1.0,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Compose the line that sits under the app bar.
  ///
  /// The **primary language label** is sourced from the loaded
  /// `state.textDetail` rather than `settings.primary` so the subtitle never
  /// disagrees with the body text — even in edge cases where the user picked
  /// a language but no version (so the API silently falls back to the
  /// default text in another language).
  ///
  /// Script / version labels still come from `settings.primary` because the
  /// `/texts/{id}/details` response does not echo those, and they are pure
  /// display sugar that the user explicitly selected.
  String _composeLabel(
    BuildContext context,
    ReaderDualLayoutSettings settings,
    ReaderState state,
  ) {
    final primary = settings.primary;
    final loadedLanguage = _resolvePrimaryLanguageLabel(context, primary, state);

    if (settings.secondaryEnabled && !settings.secondary.isUnset) {
      return '$loadedLanguage + ${settings.secondary.languageLabel}';
    }
    final parts = <String>[
      loadedLanguage.toUpperCase(),
      if (primary.scriptLabel != null) primary.scriptLabel!.toUpperCase(),
      if (primary.versionLabel != null) primary.versionLabel!.toUpperCase(),
    ];
    return parts.join(' · ');
  }

  String _resolvePrimaryLanguageLabel(
    BuildContext context,
    ReaderSlotConfig primary,
    ReaderState state,
  ) {
    final loaded = state.textDetail?.language ?? '';
    if (loaded.isEmpty) {
      return primary.languageLabel;
    }
    // Prefer the human-readable label from settings when it agrees with the
    // loaded language, otherwise render the backend value (a raw code like
    // "bo") through getLanguageName so the subtitle shows "Tibetan", not "bo".
    if (primary.languageLabel.toLowerCase() == loaded.toLowerCase() ||
        primary.languageCode.toLowerCase() == loaded.toLowerCase()) {
      return primary.languageLabel;
    }
    return getLanguageName(loaded, context);
  }
}
