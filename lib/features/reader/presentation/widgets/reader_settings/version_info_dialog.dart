import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_version_detail.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VersionInfoDialog extends ConsumerWidget {
  const VersionInfoDialog({
    super.key,
    required this.versionId,
    required this.fallbackTitle,
  });

  final String versionId;
  final String fallbackTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncInfo = ref.watch(readerVersionInfoProvider(versionId));

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
        child: asyncInfo.when(
          loading: () => _DialogShell(
            title: fallbackTitle,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (_, __) => _DialogShell(
            title: fallbackTitle,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.reader_version_details_load_error,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => ref.invalidate(
                      readerVersionInfoProvider(versionId),
                    ),
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            ),
          ),
          data: (info) => _DialogShell(
            title: info.title.isNotEmpty ? info.title : fallbackTitle,
            child: _VersionInfoBody(info: info),
          ),
        ),
      ),
    );
  }
}

class _DialogShell extends StatelessWidget {
  const _DialogShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 22),
              splashRadius: 20,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            ),
          ],
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _VersionInfoBody extends StatelessWidget {
  const _VersionInfoBody({required this.info});

  final ReaderVersionDetail info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );

    final l10n = AppLocalizations.of(context)!;
    final rows = <Widget>[];

    if (info.publishedBy != null && info.publishedBy!.isNotEmpty) {
      rows.add(_InfoRow(label: l10n.reader_published_by, value: info.publishedBy!));
    }
    if (info.publishedDate != null && info.publishedDate!.isNotEmpty) {
      rows.add(_InfoRow(label: l10n.reader_published, value: info.publishedDate!));
    }
    if (info.license != null && info.license!.isNotEmpty) {
      rows.add(_InfoRow(label: l10n.reader_license, value: info.license!));
    }
    if (info.sourceLink != null && info.sourceLink!.isNotEmpty) {
      rows.add(_InfoRow(label: l10n.source, value: info.sourceLink!));
    }
    if (info.language.isNotEmpty) {
      rows.add(_InfoRow(label: l10n.language, value: info.language));
    }
    if (info.type != null && info.type!.isNotEmpty) {
      rows.add(_InfoRow(label: l10n.reader_version_type, value: info.type!));
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rows.isEmpty)
            Text(
              l10n.reader_no_version_info,
              style: mutedStyle,
            )
          else
            ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showVersionInfoDialog(
  BuildContext context, {
  required String versionId,
  required String fallbackTitle,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => VersionInfoDialog(
      versionId: versionId,
      fallbackTitle: fallbackTitle,
    ),
  );
}
