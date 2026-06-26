import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:skeletonizer/skeletonizer.dart';

enum PracticeSectionSkeletonStyle { card, chantTile }

class PracticeSectionSkeleton extends StatelessWidget {
  const PracticeSectionSkeleton({
    super.key,
    required this.height,
    this.axis = Axis.vertical,
    this.itemCount = 1,
    this.itemWidth,
    this.itemSpacing = 12,
    this.horizontalPadding = 16,
    this.cardBorderRadius = 16,
    this.style = PracticeSectionSkeletonStyle.card,
  });

  final double height;
  final Axis axis;
  final int itemCount;
  final double? itemWidth;
  final double itemSpacing;
  final double horizontalPadding;
  final double cardBorderRadius;
  final PracticeSectionSkeletonStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Skeletonizer(
        enabled: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Bone(width: 120, height: 22),
                  Bone(width: 48, height: 18),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: height,
              child:
                  axis == Axis.horizontal
                      ? ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        itemCount: itemCount,
                        separatorBuilder:
                            (_, __) => SizedBox(width: itemSpacing),
                        itemBuilder:
                            (context, index) => _SkeletonCard(
                              width: itemWidth,
                              borderRadius: cardBorderRadius,
                            ),
                      )
                      : Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child:
                            itemCount > 1
                                ? Column(
                                  children: [
                                    for (
                                      var index = 0;
                                      index < itemCount;
                                      index++
                                    ) ...[
                                      if (index > 0)
                                        SizedBox(height: itemSpacing),
                                      Expanded(child: _buildVerticalItem()),
                                    ],
                                  ],
                                )
                                : _buildVerticalItem(),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalItem() {
    return switch (style) {
      PracticeSectionSkeletonStyle.chantTile => _ChantSkeletonCard(
        borderRadius: cardBorderRadius,
      ),
      PracticeSectionSkeletonStyle.card => _SkeletonCard(
        width: double.infinity,
        borderRadius: cardBorderRadius,
      ),
    };
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.width, required this.borderRadius});

  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? AppColors.cardBackgroundDark
                : Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Bone(
        width: double.infinity,
        height: double.infinity,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class _ChantSkeletonCard extends StatelessWidget {
  const _ChantSkeletonCard({required this.borderRadius});

  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : AppColors.grey800,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Bone(
                      width: 170,
                      height: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Bone(
                      width: double.infinity,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    Bone(
                      width: 150,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Center(child: Bone.circle(size: 40)),
            ],
          ),
        ),
      ),
    );
  }
}
