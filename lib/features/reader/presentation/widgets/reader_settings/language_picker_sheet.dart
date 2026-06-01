import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/picker_sheet_scaffold.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/picker_state_views.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguagePickerSheet extends ConsumerWidget {
  const LanguagePickerSheet({
    super.key,
    required this.textId,
    required this.selectedCode,
    required this.onSelected,
    this.title,
  });

  final String textId;
  final String selectedCode;
  final ValueChanged<ReaderLanguageOption> onSelected;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final asyncLangs = ref.watch(readerLanguagesProvider(textId));

    return PickerSheetScaffold(
      title: title ?? l10n.language,
      child: asyncLangs.when(
        loading: () => const PickerLoading(),
        error: (err, _) => PickerError(
          message: l10n.reader_languages_load_error,
          onRetry: () => ref.invalidate(readerLanguagesProvider(textId)),
        ),
        data: (langs) {
          if (langs.isEmpty) {
            return PickerEmpty(
              message: l10n.reader_no_languages,
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: langs.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.4),
            ),
            itemBuilder: (context, index) {
              final option = langs[index];
              final isSelected = option.code == selectedCode;
              return _LanguageTile(
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

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final ReaderLanguageOption option;
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  getLanguageName(option.code),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isSelected
                        ? activeColor
                        : theme.textTheme.titleMedium?.color,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${option.versionCount} versions',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(width: 12),
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

Future<void> showLanguagePickerSheet(
  BuildContext context, {
  required String textId,
  required String selectedCode,
  required ValueChanged<ReaderLanguageOption> onSelected,
  String? title,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (_) => LanguagePickerSheet(
      textId: textId,
      selectedCode: selectedCode,
      onSelected: onSelected,
      title: title,
    ),
  );
}
