import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton shown while the catalogue loads or a mantra is seeding.
///
/// Mirrors the loaded [MalaScreen] body (rendered below the app bar): a 40%
/// mantra-switcher block with side chevrons and centered text, above a 60%
/// block holding the left-aligned counter and the bead arc.
class MalaSkeleton extends StatelessWidget {
  const MalaSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            // Mantra + transliteration switcher: 40% of the space below the
            // header, centered between the chevrons.
            Expanded(flex: 40, child: _SwitcherSkeleton()),
            // Counter + bead arc: the remaining 60%.
            Expanded(flex: 60, child: _CounterAndBeadsSkeleton()),
          ],
        ),
      ),
    );
  }
}

/// Side chevrons flanking a centered mantra (large) + transliteration (small).
class _SwitcherSkeleton extends StatelessWidget {
  const _SwitcherSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Real chevrons read better than bones here.
        Skeleton.ignore(
          child: Icon(
            Icons.chevron_left,
            size: 32,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.25),
          ),
        ),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Bone(height: 32, width: 200),
              SizedBox(height: 16),
              _Bone(height: 20, width: 140),
            ],
          ),
        ),
        Skeleton.ignore(
          child: Icon(
            Icons.chevron_right,
            size: 32,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }
}

/// Left-aligned counter (big "n/108" + rounds line) above the bead arc.
class _CounterAndBeadsSkeleton extends StatelessWidget {
  const _CounterAndBeadsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        // Counter block (left-aligned), matching _CounterBlock.
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Bone(height: 40, width: 120),
              SizedBox(height: 8),
              _Bone(height: 24, width: 90),
            ],
          ),
        ),
        SizedBox(height: 16),
        // Bead arc.
        Expanded(child: _BeadArcSkeleton()),
        SizedBox(height: 24),
      ],
    );
  }
}

/// A diagonal strand of bead-sized circles approximating the bead arc.
class _BeadArcSkeleton extends StatelessWidget {
  const _BeadArcSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        // Bead diameter ≈ 15% of width (matches _radiusFactor = 0.075).
        final diameter = (width * 0.15).clamp(24.0, 64.0);
        const count = 7;

        return Stack(
          children: [
            for (var i = 0; i < count; i++)
              Builder(
                builder: (context) {
                  // Strand runs from bottom-left up to top-right.
                  final t = count == 1 ? 0.0 : i / (count - 1);
                  final left = (width - diameter) * t;
                  final top = (height - diameter) * (1 - t);
                  return Positioned(
                    left: left,
                    top: top,
                    child: _Bone(
                      height: diameter,
                      width: diameter,
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

/// A single skeleton placeholder block.
class _Bone extends StatelessWidget {
  const _Bone({
    required this.height,
    required this.width,
    this.shape = BoxShape.rectangle,
  });

  final double height;
  final double width;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey,
        shape: shape,
        borderRadius:
            shape == BoxShape.rectangle ? BorderRadius.circular(8) : null,
      ),
    );
  }
}
