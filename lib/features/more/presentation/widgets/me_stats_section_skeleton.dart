import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton placeholder for [MeStatsSection] while user stats are loading.
class MeStatsSectionSkeleton extends StatelessWidget {
  const MeStatsSectionSkeleton({super.key});

  static const _horizontalPadding = 20.0;
  static const _cardSpacing = 12.0;
  static const _borderRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.surfaceWhite;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _horizontalPadding,
        24,
        _horizontalPadding,
        24,
      ),
      child: Skeletonizer(
        enabled: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Bone.text(words: 2, fontSize: 20),
            const SizedBox(height: 16),
            _SkeletonCard(
              cardColor: cardColor,
              borderColor: borderColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Bone(width: 20, height: 20),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Bone.circle(size: 28),
                      const SizedBox(width: 8),
                      Bone.text(words: 2, fontSize: 18),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(child: Bone.text(words: 3, fontSize: 14)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      for (var i = 0; i < 7; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            children: [
                              Bone(
                                width: 20,
                                height: 12,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 8),
                              Bone(
                                width: 36,
                                height: 36,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: _cardSpacing),
            _SkeletonCard(
              cardColor: cardColor,
              borderColor: borderColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  const Bone(width: 24, height: 24),
                  const SizedBox(width: 12),
                  Expanded(child: Bone.text(words: 4, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: _cardSpacing),
            Row(
              children: [
                Expanded(
                  child: _StatCardSkeleton(
                    cardColor: cardColor,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(width: _cardSpacing),
                Expanded(
                  child: _StatCardSkeleton(
                    cardColor: cardColor,
                    borderColor: borderColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({
    required this.cardColor,
    required this.borderColor,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Color cardColor;
  final Color borderColor;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          MeStatsSectionSkeleton._borderRadius,
        ),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton({required this.cardColor, required this.borderColor});

  final Color cardColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return _SkeletonCard(
      cardColor: cardColor,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Bone.text(words: 2, fontSize: 13),
          const SizedBox(height: 12),
          Row(
            children: [
              const Bone(width: 22, height: 22),
              const SizedBox(width: 4),
              Expanded(child: Bone.text(words: 2, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }
}
