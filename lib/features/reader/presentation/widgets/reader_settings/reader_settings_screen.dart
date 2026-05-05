import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/language_picker_sheet.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/script_picker_sheet.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/slot_config_card.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/version_picker_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReaderSettingsScreen extends ConsumerWidget {
  const ReaderSettingsScreen({super.key, required this.textId});

  final String textId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readerDualSettingsProvider);
    final notifier = ref.read(readerDualSettingsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Reader Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SecondaryToggle(
                enabled: settings.secondaryEnabled,
                onChanged: notifier.setSecondaryEnabled,
              ),
              const SizedBox(height: 20),
              SlotConfigCard(
                headerLabel: 'Main text',
                config: settings.primary,
                enabled: true,
                onLanguage: () => _pickLanguage(context, ref, isPrimary: true),
                onVersion: () => _pickVersion(context, ref, isPrimary: true),
                onScript: () => _pickScript(context, ref, isPrimary: true),
              ),
              const SizedBox(height: 18),
              SlotConfigCard(
                headerLabel: 'Second version',
                config: settings.secondary,
                enabled: settings.secondaryEnabled,
                showScriptRow: false,
                onLanguage: () => _pickLanguage(context, ref, isPrimary: false),
                onVersion: () => _pickVersion(context, ref, isPrimary: false),
                onScript: () => _pickScript(context, ref, isPrimary: false),
              ),
              const SizedBox(height: 16),
              if (settings.secondaryEnabled)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'The second version will appear below each verse of the main text.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref, {
    required bool isPrimary,
  }) async {
    final settings = ref.read(readerDualSettingsProvider);
    final notifier = ref.read(readerDualSettingsProvider.notifier);
    final current = isPrimary ? settings.primary : settings.secondary;

    await showLanguagePickerSheet(
      context,
      textId: textId,
      selectedCode: current.languageCode,
      onSelected: (option) {
        if (option.code == current.languageCode) return;
        final next = ReaderSlotConfig(
          languageCode: option.code,
          languageLabel: option.label,
        );
        if (isPrimary) {
          notifier.replacePrimary(next);
        } else {
          notifier.replaceSecondary(next);
        }
      },
    );
  }

  Future<void> _pickVersion(
    BuildContext context,
    WidgetRef ref, {
    required bool isPrimary,
  }) async {
    final settings = ref.read(readerDualSettingsProvider);
    final notifier = ref.read(readerDualSettingsProvider.notifier);
    final current = isPrimary ? settings.primary : settings.secondary;

    await showVersionPickerSheet(
      context,
      textId: textId,
      languageCode: current.languageCode,
      languageLabel: current.languageLabel,
      selectedVersionId: current.versionId,
      onSelected: (option) {
        final next = current.copyWith(
          versionId: option.id,
          versionLabel: option.title,
        );
        if (isPrimary) {
          notifier.replacePrimary(next);
        } else {
          notifier.replaceSecondary(next);
        }
      },
    );
  }

  Future<void> _pickScript(
    BuildContext context,
    WidgetRef ref, {
    required bool isPrimary,
  }) async {
    final settings = ref.read(readerDualSettingsProvider);
    final notifier = ref.read(readerDualSettingsProvider.notifier);
    final current = isPrimary ? settings.primary : settings.secondary;

    await showScriptPickerSheet(
      context,
      textId: textId,
      languageCode: current.languageCode,
      languageLabel: current.languageLabel,
      selectedScriptId: current.scriptId,
      onSelected: (option) {
        final next = current.copyWith(
          scriptId: option.id,
          scriptLabel: option.label,
        );
        if (isPrimary) {
          notifier.replacePrimary(next);
        } else {
          notifier.replaceSecondary(next);
        }
      },
    );
  }
}

class _SecondaryToggle extends StatelessWidget {
  const _SecondaryToggle({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!enabled),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SHOW SECOND VERSION',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enable to add a translation or transliteration '
                      'alongside the main text.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(value: enabled, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> openReaderSettings(
  BuildContext context, {
  required String textId,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: false,
      builder: (_) => ReaderSettingsScreen(textId: textId),
    ),
  );
}
