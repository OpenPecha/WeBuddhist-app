import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_constants.dart';

/// Section header for grouped panel lists (e.g. "Tibetan (3)").
class ReaderPanelSectionHeader extends StatelessWidget {
  const ReaderPanelSectionHeader({
    super.key,
    required this.languageCode,
    required this.count,
  });

  final String languageCode;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = getLanguageLabel(languageCode, context);
    final dividerColor = ReaderPanelConstants.dividerColor(context);

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
              '$label ($count)',
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
