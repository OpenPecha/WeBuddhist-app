import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_constants.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// Body text for a panel item with an inline "MORE/ LESS" toggle.
///
/// The full [content] is displayed when [isExpanded] is true; otherwise the
/// preview is truncated at [ReaderPanelConstants.previewMaxLength] characters
/// and an inline `... MORE` affordance is appended. When the content exceeds
/// the preview length, the entire block is tappable to expand or collapse.
class ReaderPanelContentBlock extends StatelessWidget {
  const ReaderPanelContentBlock({
    super.key,
    required this.content,
    required this.language,
    required this.isExpanded,
    required this.onToggle,
  });

  final String content;
  final String language;
  final bool isExpanded;
  final VoidCallback onToggle;

  void _handleToggle() {
    HapticFeedback.selectionClick();
    onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = context.l10n;
    final fontFamily = getFontFamily(language);
    final lineHeight = getLineHeight(language);
    final fontSize = language == 'bo' ? 20.0 : 16.0;

    final isToggleable =
        content.length > ReaderPanelConstants.previewMaxLength;
    final isTruncated =
        !isExpanded && isToggleable;
    final displayContent = isTruncated
        ? content.substring(0, ReaderPanelConstants.previewMaxLength)
        : content;

    final bodyStyle = TextStyle(
      fontFamily: fontFamily,
      height: lineHeight,
      fontSize: fontSize,
      color: theme.colorScheme.onSurface,
    );
    final actionStyle = bodyStyle.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
      fontWeight: FontWeight.w600,
      fontSize: fontSize * 0.85,
    );

    final Widget contentWidget;
    if (isTruncated) {
      contentWidget = Text.rich(
        TextSpan(
          style: bodyStyle,
          children: [
            TextSpan(text: displayContent),
            TextSpan(
              text: ' ...${localizations.more.toUpperCase()}',
              style: actionStyle,
            ),
          ],
        ),
      );
    } else if (isExpanded && isToggleable) {
      contentWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(content, style: bodyStyle),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              localizations.less.toUpperCase(),
              style: actionStyle,
            ),
          ),
        ],
      );
    } else {
      contentWidget = Text(content, style: bodyStyle);
    }

    if (!isToggleable) {
      return contentWidget;
    }

    return GestureDetector(
      onTap: _handleToggle,
      behavior: HitTestBehavior.opaque,
      child: contentWidget,
    );
  }
}
