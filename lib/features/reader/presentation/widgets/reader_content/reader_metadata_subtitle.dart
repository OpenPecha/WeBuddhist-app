import 'package:flutter/material.dart';
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
    final settings = ref.watch(readerDualSettingsProvider);
    if (state.textDetail == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final text = _composeLabel(settings, state);

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

  String _composeLabel(
    ReaderDualLayoutSettingsLike settings,
    ReaderState state,
  ) {
    final primary = settings.primary;
    if (settings.secondaryEnabled) {
      return '${primary.languageLabel} + ${settings.secondary.languageLabel}';
    }
    final parts = <String>[
      primary.languageLabel.toUpperCase(),
      if (primary.scriptLabel != null) primary.scriptLabel!.toUpperCase(),
      if (primary.versionLabel != null) primary.versionLabel!.toUpperCase(),
    ];
    return parts.join(' · ');
  }
}

typedef ReaderDualLayoutSettingsLike = ReaderDualLayoutSettings;
