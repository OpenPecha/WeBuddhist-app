import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_actions/action_button.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/share_provider.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
      bottom: 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                    icon: PhosphorIconsRegular.chatText,
                    label: localizations.text_commentary,
                    onTap: () {
                      notifier.toggleCommentary(segment.segmentId);
                      if (!state.isCommentaryOpen) {
                        onOpenCommentary?.call();
                      }
                    },
                  ),
                  // AI button
                  ActionButton(
                    icon: PhosphorIconsRegular.sparkle,
                    label: localizations.ask_ai,
                    onTap:
                        () => {
                          // show a comming soon snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(localizations.comingSoonHeadline),
                              duration: Duration(seconds: 2),
                            ),
                          ),
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
    final localizations = context.l10n;
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
    context.pushNamed('choose-image', extra: plainText);
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
      final result = await ref.read(shareUrlProvider(params).future);

      final shortUrl = result.fold(
        (failure) => throw Exception('Failed to generate share URL: ${failure.message}'),
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
    return ActionButton(
      icon: PhosphorIconsRegular.shareNetwork,
      label: localizations.share,
      onTap: _handleShare,
      isLoading: _isLoading,
    );
  }
}
