import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_script_option.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/picker_sheet_scaffold.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/picker_state_views.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScriptPickerSheet extends ConsumerWidget {
  const ScriptPickerSheet({
    super.key,
    required this.textId,
    required this.languageCode,
    required this.languageLabel,
    required this.selectedScriptId,
    required this.onSelected,
  });

  final String textId;
  final String languageCode;
  final String languageLabel;
  final String? selectedScriptId;
  final ValueChanged<ReaderScriptOption> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final query = ReaderLanguageQuery(textId: textId, language: languageCode);
    final asyncScripts = ref.watch(readerScriptsProvider(query));

    return PickerSheetScaffold(
      title: l10n.reader_script_title(languageLabel),
      child: asyncScripts.when(
        loading: () => const PickerLoading(),
        error: (_, __) => PickerError(
          message: l10n.reader_scripts_load_error,
          onRetry: () => ref.invalidate(readerScriptsProvider(query)),
        ),
        data: (scripts) {
          if (scripts.isEmpty) {
            return PickerEmpty(
              message: l10n.reader_no_scripts_in_language(languageLabel),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: scripts.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.4),
            ),
            itemBuilder: (context, index) {
              final option = scripts[index];
              final isSelected = option.id == selectedScriptId;
              return _ScriptTile(
                option: option,
                isSelected: isSelected,
                onTap: () {
                  onSelected(option);
                  Navigator.of(context).pop();
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ScriptTile extends StatelessWidget {
  const _ScriptTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final ReaderScriptOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? activeColor
                            : theme.textTheme.titleMedium?.color,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (option.name != null && option.name!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        option.name!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: 18,
                child: isSelected
                    ? Icon(Icons.check, size: 18, color: activeColor)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showScriptPickerSheet(
  BuildContext context, {
  required String textId,
  required String languageCode,
  required String languageLabel,
  required String? selectedScriptId,
  required ValueChanged<ReaderScriptOption> onSelected,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (_) => ScriptPickerSheet(
      textId: textId,
      languageCode: languageCode,
      languageLabel: languageLabel,
      selectedScriptId: selectedScriptId,
      onSelected: onSelected,
    ),
  );
}
