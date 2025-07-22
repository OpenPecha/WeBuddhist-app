import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_html_widget.dart';
import 'package:flutter_pecha/features/texts/data/providers/texts_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/text_version_language_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/font_size_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/selected_segment_provider.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/font_size_selector.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/segment_action_bar.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/text_search_delegate.dart';
import 'package:flutter_pecha/shared/utils/helper_fucntions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class TextReaderScreen extends ConsumerStatefulWidget {
  const TextReaderScreen({
    super.key,
    required this.textId,
    required this.contentId,
    this.segmentId,
  });
  final String textId;
  final String contentId;
  final String? segmentId;

  @override
  ConsumerState<TextReaderScreen> createState() => _TextReaderScreenState();
}

class _TextReaderScreenState extends ConsumerState<TextReaderScreen> {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final direction = 'next';

  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(fontSizeProvider);
    final selectedIndex = ref.watch(selectedSegmentProvider);

    final params = TextDetailsParams(
      textId: widget.textId,
      contentId: widget.contentId,
      segmentId: widget.segmentId,
      direction: direction,
    );

    final textDetails = ref.watch(textDetailsFutureProvider(params));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            ref.read(selectedSegmentProvider.notifier).state = null;
            Navigator.pop(context);
          },
        ),
        toolbarHeight: 50,
        actions: [
          // search icon
          IconButton(
            onPressed: () async {
              final details = textDetails.value;
              if (details != null) {
                final selectedIndex = await showSearch<int?>(
                  context: context,
                  delegate: TextSearchDelegate(textDetails: details, ref: ref),
                );

                if (selectedIndex != null && mounted) {
                  itemScrollController.scrollTo(
                    index: selectedIndex + 1, // +1 for the header
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              }
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => showFontSizeSelector(context, ref),
            icon: const Icon(Icons.text_increase),
          ),
          GestureDetector(
            onTap: () {
              ref
                  .read(textVersionLanguageProvider.notifier)
                  .setLanguage(textDetails.value?.textDetail.language ?? "en");
              context.push(
                '/texts/version_selection',
                extra: {"textId": textDetails.value?.textDetail.id},
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    textDetails.value?.textDetail.language.toUpperCase() ?? "",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.only(right: 20),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: const Color(0xFFB6D7D7)),
        ),
      ),
      body: textDetails.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (response) {
          if (response.content.sections.isEmpty) {
            return const Center(child: Text("No content available"));
          }
          final firstSection = response.content.sections[0];
          final textId = response.textDetail.id;
          final contentId = response.content.id;
          if (firstSection.segments.isEmpty) {
            return const Center(child: Text("No segments available"));
          }
          return Stack(
            children: [
              ScrollablePositionedList.builder(
                itemScrollController: itemScrollController,
                itemPositionsListener: itemPositionsListener,
                itemCount: firstSection.segments.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // This is the header
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            response.textDetail.title,
                            style: TextStyle(
                              fontSize: getFontSize(
                                response.textDetail.language,
                              ),
                              fontFamily: getFontFamily(
                                response.textDetail.language,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            firstSection.title ?? '',
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: getFontFamily(
                                response.textDetail.language,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  }

                  final segmentIndex = index - 1;
                  final segment = firstSection.segments[segmentIndex];
                  final segmentNumber = segment.segmentNumber
                      .toString()
                      .padLeft(2);
                  final content = segment.content;
                  final isSelected = selectedIndex == segmentIndex;

                  return GestureDetector(
                    onTap: () {
                      ref.read(selectedSegmentProvider.notifier).state =
                          ref.read(selectedSegmentProvider) == segmentIndex
                              ? null
                              : segmentIndex;
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Theme.of(
                                  context,
                                ).colorScheme.primary.withAlpha(25)
                                : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: SizedBox(
                              width: 30,
                              child: Text(
                                segmentNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SegmentHtmlWidget(
                              htmlContent: content ?? '',
                              segmentIndex: segmentIndex,
                              fontSize: fontSize,
                              isSelected: isSelected,
                              language: response.textDetail.language,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (selectedIndex != null)
                SegmentActionBar(
                  text: firstSection.segments[selectedIndex].content ?? '',
                  textId: textId,
                  contentId: contentId,
                  segmentId: firstSection.segments[selectedIndex].segmentId,
                  language: response.textDetail.language,
                  onClose:
                      () =>
                          ref.read(selectedSegmentProvider.notifier).state =
                              null,
                ),
            ],
          );
        },
      ),
    );
  }
}

// Utility function to show font size selector
void showFontSizeSelector(BuildContext context, WidgetRef ref) {
  showDialog(context: context, builder: (context) => const FontSizeSelector());
}
