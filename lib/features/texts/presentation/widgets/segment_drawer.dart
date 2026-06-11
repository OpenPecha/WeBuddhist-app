import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/use_case_providers.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SegmentDrawer extends ConsumerWidget {
  final String segmentId;

  const SegmentDrawer({super.key, required this.segmentId});

  static Future<void> show(BuildContext context, String segmentId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => SegmentDrawer(segmentId: segmentId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segmentAsync = ref.watch(segmentDetailProvider(segmentId));

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              _buildDragHandle(context),
              Expanded(
                child: segmentAsync.when(
                  data: (segment) => _SegmentContent(
                    title: segment.textTitle,
                    content: segment.content,
                    scrollController: scrollController,
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: ErrorStateWidget(
                      error: error,
                      onRetry: () =>
                          ref.invalidate(segmentDetailProvider(segmentId)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SegmentContent extends StatelessWidget {
  final String title;
  final String content;
  final ScrollController scrollController;

  const _SegmentContent({
    required this.title,
    required this.content,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final lineHeight = getLineHeight(language) ?? 1.6;
    final fontFamily = getSystemFontFamily(language);

    return SingleChildScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: lineHeight,
                fontFamily: fontFamily,
                color: theme.colorScheme.onSurface,
              ),
            ),
          if (title.isNotEmpty) const SizedBox(height: 16),
          SelectableText(
            content,
            style: TextStyle(
              fontSize: 16,
              height: lineHeight,
              fontFamily: fontFamily,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
