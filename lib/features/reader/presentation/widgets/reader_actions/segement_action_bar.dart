import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/presentation/controllers/bookmark_controller.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Converts HTML to plain text, removing specified elements using regex
String _htmlToPlainText(String htmlString) {
  String cleanedHtml = _removeHtmlElementsWithContent(htmlString, ['sup', 'i']);
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

/// "Resources" bottom panel: Copy/Share icon buttons + Commentaries/Versions
/// list tiles. Appears when a segment is selected and no split panel is open.
class SegmentActionBar extends ConsumerStatefulWidget {
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
  ConsumerState<SegmentActionBar> createState() => _SegmentActionBarState();
}

class _SegmentActionBarState extends ConsumerState<SegmentActionBar> {
  bool _isBookmarking = false;

  Future<void> _handleBookmark() async {
    if (_isBookmarking) return;
    HapticFeedback.lightImpact();
    setState(() => _isBookmarking = true);
    try {
      await BookmarkController(
        ref: ref,
        context: context,
      ).toggleVerse(widget.segment.segmentId);
    } finally {
      if (mounted) setState(() => _isBookmarking = false);
    }
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
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    final state = ref.watch(readerNotifierProvider(widget.params));
    final notifier = ref.read(readerNotifierProvider(widget.params).notifier);

    final content = widget.segment.content;
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }

    final isBookmarked = ref.watch(
      isBookmarkedProvider(
        BookmarkTarget(
          type: BookmarkType.verse,
          sourceId: widget.segment.segmentId,
        ),
      ),
    );

    return _ResourcesPanel(
      onDismiss: widget.onClose,
      copyButton: _IconActionButton(
        icon: AppAssets.readerCopy,
        label: localizations.copy,
        onTap: () {
          HapticFeedback.lightImpact();
          _handleCopy(context, content);
        },
      ),
      shareButton: _ShareButton(
        textId: widget.params.textId,
        segmentId: widget.segment.segmentId,
        language: state.textDetail?.language ?? 'en',
        onClose: widget.onClose,
      ),
      bookmarkButton: _IconActionButton(
        icon:
            isBookmarked
                ? AppAssets.bookmarkSimpleFill
                : AppAssets.bookmarkSimple,
        label: localizations.bookmark,
        isLoading: _isBookmarking,
        onTap: _handleBookmark,
      ),
      tiles: [
        _ResourceTile(
          icon: AppAssets.readerCommentary,
          label: localizations.text_commentary,
          onTap: () {
            HapticFeedback.lightImpact();
            notifier.toggleCommentary(widget.segment.segmentId);
            if (!state.isCommentaryOpen) {
              widget.onOpenCommentary?.call();
            }
          },
        ),
        _ResourceTile(
          icon: AppAssets.readerVersion,
          label: localizations.version,
          onTap: () {
            HapticFeedback.lightImpact();
            notifier.toggleTranslation(widget.segment.segmentId);
            if (!state.isTranslationOpen) {
              widget.onOpenTranslation?.call();
            }
          },
        ),
      ],
    );
  }
}

/// Bottom-sheet-style panel. Dismissible by swiping downward.
/// Layout: drag handle → [Copy | Share | Bookmark] → Resources → tiles.
class _ResourcesPanel extends StatelessWidget {
  final VoidCallback onDismiss;
  final Widget copyButton;
  final Widget shareButton;
  final Widget bookmarkButton;
  final List<Widget> tiles;

  const _ResourcesPanel({
    required this.onDismiss,
    required this.copyButton,
    required this.shareButton,
    required this.bookmarkButton,
    required this.tiles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBackgroundColor = theme.colorScheme.onSurface.withValues(
      alpha: 0.05,
    );
    const radius = Radius.circular(20);

    return Dismissible(
      key: const ValueKey('segment_action_panel'),
      direction: DismissDirection.down,
      onDismissed: (_) {
        HapticFeedback.lightImpact();
        onDismiss();
      },
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.only(
          topLeft: radius,
          topRight: radius,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: radius,
                  topRight: radius,
                ),
                child: ColoredBox(
                  color: cardBackgroundColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle pill
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 8),
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Copy / Share / Bookmark icon buttons aligned to start
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Row(
                  children: [
                    copyButton,
                    const SizedBox(width: 16),
                    shareButton,
                    const SizedBox(width: 16),
                    bookmarkButton,
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: Text(
                  context.l10n.resources,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
              Divider(height: 1, thickness: 1, color: theme.dividerColor),
              // Commentaries / Versions tiles with dividers
              for (final tile in tiles) ...[
                tile,
                // Divider(height: 1, thickness: 1, color: theme.dividerColor),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon-above-label action button used in the Copy/Share row.
class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _IconActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurface;
    final backgroundColor = theme.colorScheme.onSurface.withValues(alpha: 0.05);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        child: SizedBox(
          width: 88,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                else
                  Icon(icon, size: 26, color: foreground),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foreground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width list tile for Commentaries / Versions with a trailing chevron.
class _ResourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ResourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(label, style: theme.textTheme.bodyLarge),
      trailing: Icon(
        AppAssets.readerChevronRight,
        size: 24,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      onTap: onTap,
    );
  }
}

/// Share button — handles URL generation and loading state.
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
      final shareUrl =
          DeepLinkUrlBuilder.readerSegmentLink(
            textId: widget.textId,
            segmentId: widget.segmentId,
            language: widget.language,
          ).toString();

      if (!mounted) return;

      final sharePositionOrigin = getSharePositionOrigin(context: context);
      await SharePlus.instance.share(
        ShareParams(text: shareUrl, sharePositionOrigin: sharePositionOrigin),
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
    return _IconActionButton(
      icon: AppAssets.readerShare,
      label: context.l10n.share,
      onTap: _handleShare,
      isLoading: _isLoading,
    );
  }
}
