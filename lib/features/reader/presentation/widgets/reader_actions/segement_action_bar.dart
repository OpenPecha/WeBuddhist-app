import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/share_provider.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Converts HTML to plain text, removing specified elements using regex
String _htmlToPlainText(String htmlString) {
  // First remove content within specified tags (sup, i)
  String cleanedHtml = _removeHtmlElementsWithContent(htmlString, ['sup', 'i']);
  // Then strip all remaining HTML tags
  return cleanedHtml.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}

String _removeHtmlElementsWithContent(String html, List<String> tagsToRemove) {
  String result = html;
  for (String tag in tagsToRemove) {
    RegExp regex = RegExp(
      '<$tag(?:\\s[^>]*)?>.*?<\\/$tag>',
      caseSensitive: false,
      dotAll: true,
    );
    result = result.replaceAll(regex, '');
  }
  return result;
}

/// Action bar for segment interactions (commentary, copy, share, image)
class SegmentActionBar extends ConsumerWidget {
  final Segment segment;
  final ReaderParams params;
  final VoidCallback onClose;
  final VoidCallback? onOpenCommentary;
  final VoidCallback? onOpenTranslation;

  const SegmentActionBar({
    super.key,
    required this.segment,
    required this.params,
    required this.onClose,
    this.onOpenCommentary,
    this.onOpenTranslation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = context.l10n;
    final state = ref.watch(readerNotifierProvider(params));
    final notifier = ref.read(readerNotifierProvider(params).notifier);

    final content = segment.content;
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: _BottomActionPanel(
        onDismiss: onClose,
        children: [
          // Versions button
          _ActionCard(
            icon: AppAssets.readerVersion,
            label: localizations.version,
            onTap: () {
              HapticFeedback.lightImpact();
              notifier.toggleTranslation(segment.segmentId);
              if (!state.isTranslationOpen) {
                onOpenTranslation?.call();
              }
            },
          ),
          // Commentary button
          _ActionCard(
            icon: AppAssets.readerCommentary,
            label: localizations.text_commentary,
            onTap: () {
              HapticFeedback.lightImpact();
              notifier.toggleCommentary(segment.segmentId);
              if (!state.isCommentaryOpen) {
                onOpenCommentary?.call();
              }
            },
          ),
          // Copy button
          _ActionCard(
            icon: AppAssets.readerCopy,
            label: localizations.copy,
            onTap: () {
              HapticFeedback.lightImpact();
              _handleCopy(context, content);
            },
          ),
          // Share button
          _ShareButton(
            textId: params.textId,
            segmentId: segment.segmentId,
            language: state.textDetail?.language ?? 'en',
            onClose: onClose,
          ),
        ],
      ),
    );
  }

  void _handleCopy(BuildContext context, String content) {
    final localizations = context.l10n;
    final textWithLineBreaks = normalizeSegmentHtml(
      content,
    ).replaceAll('<br>', '\n');
    final plainText = _htmlToPlainText(textWithLineBreaks);
    Clipboard.setData(ClipboardData(text: plainText));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(localizations.copied)));
    onClose();
  }
}

/// Bottom-sheet-style panel that hosts the segment action cards. Anchored to
/// the bottom edge with rounded top corners, it can be dismissed by swiping
/// downwards (via [onDismiss]) and respects the home indicator through
/// [SafeArea]. Children are laid out as a horizontally scrollable row of cards.
class _BottomActionPanel extends StatelessWidget {
  final List<Widget> children;
  final VoidCallback onDismiss;

  const _BottomActionPanel({required this.children, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const radius = Radius.circular(20);

    // Slightly offset from the reader background so the panel reads as a
    // distinct surface without a hard border.
    final panelColor = Color.alphaBlend(
      (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
      theme.scaffoldBackgroundColor,
    );

    return Dismissible(
      key: const ValueKey('segment_action_panel'),
      direction: DismissDirection.down,
      onDismissed: (_) {
        HapticFeedback.lightImpact();
        onDismiss();
      },
      child: Material(
        color: panelColor,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(
          topLeft: radius,
          topRight: radius,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single filled action card: icon over label inside a rounded surface.
/// Shows a spinner in place of the icon while [isLoading].
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04);
    final foreground = theme.colorScheme.onSurface;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        // Size to the label so it is never truncated; a min width keeps
        // short-label cards (Copy/Share) from looking cramped.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                else
                  Icon(icon, size: 24, color: foreground),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Share button with loading state
class _ShareButton extends ConsumerStatefulWidget {
  final String textId;
  final String segmentId;
  final String language;
  final VoidCallback onClose;

  const _ShareButton({
    required this.textId,
    required this.segmentId,
    required this.language,
    required this.onClose,
  });

  @override
  ConsumerState<_ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends ConsumerState<_ShareButton> {
  bool _isLoading = false;

  Future<void> _handleShare() async {
    HapticFeedback.lightImpact();
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final params = ShareUrlParams(
        textId: widget.textId,
        segmentId: widget.segmentId,
        language: widget.language,
      );
      final result = await ref.read(shareUrlProvider(params).future);

      final shortUrl = result.fold(
        (failure) =>
            throw Exception('Failed to generate share URL: ${failure.message}'),
        (url) => url,
      );

      if (!mounted) return;

      final sharePositionOrigin = getSharePositionOrigin(context: context);
      await SharePlus.instance.share(
        ShareParams(text: shortUrl, sharePositionOrigin: sharePositionOrigin),
      );
      widget.onClose();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.shareError(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    return _ActionCard(
      icon: AppAssets.readerShare,
      label: localizations.share,
      onTap: _handleShare,
      isLoading: _isLoading,
    );
  }
}
