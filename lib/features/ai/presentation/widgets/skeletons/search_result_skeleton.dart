import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:skeletonizer/skeletonizer.dart';

enum SearchResultSkeletonMode { all, titles, contents }

/// Skeleton loading widget for the AI search results tabs.
///
/// Each mode mirrors the tab it is shown in so loading content does not jump
/// from mixed-section placeholders into a single result-list shape.
class SearchResultSkeleton extends StatelessWidget {
  const SearchResultSkeleton({
    super.key,
    this.mode = SearchResultSkeletonMode.all,
    this.itemCount = 4,
  });

  final SearchResultSkeletonMode mode;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: switch (mode) {
        SearchResultSkeletonMode.titles => _TitleResultList(
          itemCount: itemCount,
        ),
        SearchResultSkeletonMode.contents => _ContentResultList(
          itemCount: itemCount,
        ),
        SearchResultSkeletonMode.all => _AllResultList(itemCount: itemCount),
      },
    );
  }
}

class _AllResultList extends StatelessWidget {
  const _AllResultList({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const _SectionHeaderSkeleton(width: 72),
        for (var i = 0; i < 3; i++) _TitleResultCardSkeleton(index: i),
        const SizedBox(height: 24),
        const _SectionHeaderSkeleton(width: 96),
        for (var i = 0; i < itemCount.clamp(1, 3); i++)
          _ContentResultCardSkeleton(index: i),
        const SizedBox(height: 24),
        const _SectionHeaderSkeleton(width: 84),
        for (var i = 0; i < 2; i++) _TitleResultCardSkeleton(index: i),
      ],
    );
  }
}

class _TitleResultList extends StatelessWidget {
  const _TitleResultList({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: itemCount,
      itemBuilder:
          (context, index) =>
              _TitleResultCardSkeleton(index: index, useOuterListPadding: true),
    );
  }
}

class _ContentResultList extends StatelessWidget {
  const _ContentResultList({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) => _ContentResultCardSkeleton(index: index),
    );
  }
}

class _SectionHeaderSkeleton extends StatelessWidget {
  const _SectionHeaderSkeleton({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 16, top: 8),
      child: Bone(
        width: width,
        height: 22,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _TitleResultCardSkeleton extends StatelessWidget {
  const _TitleResultCardSkeleton({
    required this.index,
    this.useOuterListPadding = false,
  });

  final int index;
  final bool useOuterListPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          useOuterListPadding
              ? const EdgeInsets.only(bottom: 12)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: Bone.text(words: index.isEven ? 4 : 6)),
            const SizedBox(width: 12),
            const Skeleton.ignore(child: Icon(Icons.chevron_right, size: 20)),
          ],
        ),
      ),
    );
  }
}

class _ContentResultCardSkeleton extends StatelessWidget {
  const _ContentResultCardSkeleton({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      margin: TextScreenConstants.cardMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Bone.text(words: index.isEven ? 3 : 5, fontSize: 18),
          const SizedBox(height: TextScreenConstants.smallVerticalSpacing),
          const Divider(height: TextScreenConstants.thinDividerThickness),
          const SizedBox(height: TextScreenConstants.contentVerticalSpacing),
          Container(
            width: double.infinity,
            padding: TextScreenConstants.cardInnerPaddingValue,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(
                TextScreenConstants.cardBorderRadius,
              ),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: TextScreenConstants.thinDividerThickness,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(words: 9, fontSize: 18),
                const SizedBox(height: 6),
                Bone.text(words: index.isEven ? 6 : 8, fontSize: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
