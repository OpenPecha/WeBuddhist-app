import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/texts/data/models/text_detail.dart';

/// Footer shown at the end of the active (plan/target) segments when the reader
/// is in its collapsed state. Exposes a "Read Full Text" action that reveals the
/// rest of the text, followed by a small metadata block (title / source /
/// license) sourced from [textDetail].
class ReadFullTextFooter extends StatelessWidget {
  final TextDetail? textDetail;
  final VoidCallback onReadFullText;

  const ReadFullTextFooter({
    super.key,
    required this.textDetail,
    required this.onReadFullText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final sourceLink = textDetail?.sourceLink;
    final license = textDetail?.license;
    final title = textDetail?.title;

    final metadataStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
    );

    return Padding(
      // Extra bottom padding so the footer (and its button) clears the
      // floating audio player widget pinned at the bottom of the reader.
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Material(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(
                ReaderConstants.segmentBorderRadius,
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onReadFullText,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      l10n.read_full_text,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (title != null && title.isNotEmpty)
            Text(title, style: metadataStyle, textAlign: TextAlign.center),
          if (sourceLink != null && sourceLink.isNotEmpty)
            Text(
              '${l10n.reader_source_label}: $sourceLink',
              style: metadataStyle,
              textAlign: TextAlign.center,
            ),
          if (license != null && license.isNotEmpty)
            Text(
              '${l10n.reader_license_label}: $license',
              style: metadataStyle,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
