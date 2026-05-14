import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_version_detail.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/picker_sheet_scaffold.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/picker_state_views.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/version_info_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VersionPickerSheet extends ConsumerWidget {
  const VersionPickerSheet({
    super.key,
    required this.textId,
    required this.languageCode,
    required this.languageLabel,
    required this.selectedVersionId,
    required this.onSelected,
  });

  final String textId;
  final String languageCode;
  final String languageLabel;
  final String? selectedVersionId;
  final ValueChanged<ReaderVersionDetail> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final query = ReaderLanguageQuery(textId: textId, language: languageCode);
    final asyncVersions = ref.watch(readerVersionsProvider(query));

    return PickerSheetScaffold(
      title: 'Version · $languageLabel',
      child: asyncVersions.when(
        loading: () => const PickerLoading(),
        error: (_, __) => PickerError(
          message: 'Failed to load versions.',
          onRetry: () => ref.invalidate(readerVersionsProvider(query)),
        ),
        data: (versions) {
          if (versions.isEmpty) {
            return PickerEmpty(
              message: 'No versions available in $languageLabel yet.',
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: versions.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.4),
            ),
            itemBuilder: (context, index) {
              final option = versions[index];
              final isSelected = option.id == selectedVersionId;
              return _VersionTile(
                option: option,
                isSelected: isSelected,
                onInfo: () => showVersionInfoDialog(
                  context,
                  versionId: option.id,
                  fallbackTitle: option.title,
                ),
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

class _VersionTile extends StatelessWidget {
  const _VersionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.onInfo,
  });

  final ReaderVersionDetail option;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final subtitle = _composeSubtitle(option);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? activeColor
                            : theme.textTheme.titleMedium?.color,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
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
              IconButton(
                onPressed: onInfo,
                icon: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                splashRadius: 18,
                tooltip: 'About this version',
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

  String? _composeSubtitle(ReaderVersionDetail v) {
    final parts = <String>[
      if (v.publishedBy != null && v.publishedBy!.isNotEmpty) v.publishedBy!,
      if (v.publishedDate != null && v.publishedDate!.isNotEmpty)
        v.publishedDate!,
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }
}

Future<void> showVersionPickerSheet(
  BuildContext context, {
  required String textId,
  required String languageCode,
  required String languageLabel,
  required String? selectedVersionId,
  required ValueChanged<ReaderVersionDetail> onSelected,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (_) => VersionPickerSheet(
      textId: textId,
      languageCode: languageCode,
      languageLabel: languageLabel,
      selectedVersionId: selectedVersionId,
      onSelected: onSelected,
    ),
  );
}
