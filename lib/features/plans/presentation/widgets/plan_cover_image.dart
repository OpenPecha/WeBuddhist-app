import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

class PlanCoverImage extends StatelessWidget {
  final ResponsiveImage? image;
  final double? height;

  const PlanCoverImage({super.key, required this.image, this.height});

  @override
  Widget build(BuildContext context) {
    final double resolvedHeight =
        height ?? MediaQuery.of(context).size.height * 0.3;

    return Container(
      height: resolvedHeight,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ResponsiveCoverImage(
        image: image,
        width: double.infinity,
        height: resolvedHeight,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(12),
        errorWidget: const Center(child: Icon(Icons.broken_image, size: 80)),
      ),
    );
  }
}
