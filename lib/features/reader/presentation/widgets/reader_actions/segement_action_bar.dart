import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/reader/data/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_actions/action_button.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/share_provider.dart';
import 'package:flutter_pecha/features/texts/models/segment.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  const SegmentActionBar({
    super.key,
    required this.segment,
    required this.params,
    required this.onClose,
    this.onOpenCommentary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final state = ref.watch(readerNotifierProvider(params));
    final notifier = ref.read(readerNotifierProvider(params).notifier);

    final content = segment.content;
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(18),
          color: Theme.of(context).cardColor,
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Commentary button
                  ActionButton(
                    icon: Icons.comment_outlined,
                    label: localizations.text_commentary,
                    onTap: () {
                      notifier.toggleCommentary(segment.segmentId);
                      if (!state.isCommentaryOpen) {
                        onOpenCommentary?.call();
                      }
                    },
                  ),
                  // Copy button
                  ActionButton(
                    icon: Icons.copy,
                    label: localizations.copy,
                    onTap: () => _handleCopy(context, content),
                  ),
                  // Share button
                  _ShareButton(
                    textId: params.textId,
                    segmentId: segment.segmentId,
                    language: state.textDetail?.language ?? 'en',
                    onClose: onClose,
                  ),
                  // Image button
                  ActionButton(
                    icon: Icons.image_outlined,
                    label: localizations.image,
                    onTap: () => _handleImage(context, content),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleCopy(BuildContext context, String content) {
    final localizations = AppLocalizations.of(context)!;
    final textWithLineBreaks = content.replaceAll("<br>", "\n");
    final plainText = _htmlToPlainText(textWithLineBreaks);
    Clipboard.setData(ClipboardData(text: plainText));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(localizations.copied)));
    onClose();
  }

  void _handleImage(BuildContext context, String content) {
    final textWithLineBreaks = content.replaceAll("<br>", "\n");
    final plainText = _htmlToPlainText(textWithLineBreaks);
    context.push('/texts/segment_image/choose_image', extra: plainText);
    onClose();
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
      final shortUrl = await ref.read(shareUrlProvider(params).future);

      if (!mounted) return;

      final sharePositionOrigin = getSharePositionOrigin(context: context);
      await SharePlus.instance.share(
        ShareParams(text: shortUrl, sharePositionOrigin: sharePositionOrigin),
      );
      widget.onClose();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to share: $e')));
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
    final localizations = AppLocalizations.of(context)!;
    return ActionButton(
      icon: Icons.share,
      label: localizations.share,
      onTap: _handleShare,
      isLoading: _isLoading,
    );
  }
}
