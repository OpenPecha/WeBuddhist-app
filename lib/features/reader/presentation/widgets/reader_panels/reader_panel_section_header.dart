import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_constants.dart';

/// Section header for grouped panel lists.
///
/// Renders as `"Tibetan (3)"` when [count] is non-null, or just the language
/// label (e.g. `"English"`) when [count] is null \u2014 used by empty-language
/// placeholder sections.
class ReaderPanelSectionHeader extends StatelessWidget {
  const ReaderPanelSectionHeader({
    super.key,
    required this.languageCode,
    this.count,
  });

  final String languageCode;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = getLanguageName(languageCode, context);
    final dividerColor = ReaderPanelConstants.dividerColor(context);
    final title = count == null ? label : '$label ($count)';

    return Padding(
      padding: const EdgeInsets.only(top: ReaderPanelConstants.sectionSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ReaderPanelConstants.horizontalPadding,
              0,
              ReaderPanelConstants.horizontalPadding,
              ReaderPanelConstants.contentSpacing,
            ),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
          Container(height: 1, color: dividerColor),
        ],
      ),
    );
  }
}
