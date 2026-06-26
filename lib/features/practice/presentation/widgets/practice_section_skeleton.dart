import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
  });

  final double height;
  final Axis axis;
  final int itemCount;
  final double? itemWidth;
  final double itemSpacing;
  final double horizontalPadding;
  final double cardBorderRadius;

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
                                      Expanded(
                                        child: _SkeletonCard(
                                          width: double.infinity,
                                          borderRadius: cardBorderRadius,
                                        ),
                                      ),
                                    ],
                                  ],
                                )
                                : _SkeletonCard(
                                  width: double.infinity,
                                  borderRadius: cardBorderRadius,
                                ),
                      ),
            ),
          ],
        ),
      ),
    );
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
