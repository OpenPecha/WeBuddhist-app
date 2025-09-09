import 'package:flutter/material.dart';

class PlanCoverImage extends StatelessWidget {
  final String imagePath;
  final String heroTag;
  final double? height;

  const PlanCoverImage({
    super.key,
    required this.imagePath,
    this.heroTag = 'plan_image',
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16, top: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            imagePath,
            width: double.infinity,
            height: height ?? MediaQuery.of(context).size.height * 0.23,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
