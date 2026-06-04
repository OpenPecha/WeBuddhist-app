import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_constants.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// Body text for a panel item with an inline "Show more / Show less" toggle.
///
/// The full [content] is displayed when [isExpanded] is true; otherwise the
/// preview is truncated at [ReaderPanelConstants.previewMaxLength] characters
/// and an inline `... MORE` affordance is appended.
class ReaderPanelContentBlock extends StatefulWidget {
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

  @override
  State<ReaderPanelContentBlock> createState() =>
      _ReaderPanelContentBlockState();
}

class _ReaderPanelContentBlockState extends State<ReaderPanelContentBlock> {
  late final TapGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = TapGestureRecognizer()..onTap = _handleToggle;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  void _handleToggle() {
    HapticFeedback.selectionClick();
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = context.l10n;
    final fontFamily = getFontFamily(widget.language);
    final lineHeight = getLineHeight(widget.language);
    final fontSize = widget.language == 'bo' ? 20.0 : 16.0;

    final isTruncated = !widget.isExpanded &&
        widget.content.length > ReaderPanelConstants.previewMaxLength;
    final displayContent = isTruncated
        ? widget.content.substring(0, ReaderPanelConstants.previewMaxLength)
        : widget.content;

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

    if (isTruncated) {
      return Text.rich(
        TextSpan(
          style: bodyStyle,
          children: [
            TextSpan(text: displayContent),
            TextSpan(
              text: ' ...${localizations.more.toUpperCase()}',
              style: actionStyle,
              recognizer: _recognizer,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.content, style: bodyStyle),
        if (widget.isExpanded &&
            widget.content.length > ReaderPanelConstants.previewMaxLength)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: _handleToggle,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                localizations.less.toUpperCase(),
                style: actionStyle,
              ),
            ),
          ),
      ],
    );
  }
}
