import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

class Series {
  final String id;
  final String title;
  final String description;
  final ResponsiveImage? coverImage;
  final bool featured;
  final int totalDays;
  final List<Plan> plans;

  const Series({
    required this.id,
    required this.title,
    required this.description,
    this.coverImage,
    this.featured = false,
    this.totalDays = 0,
    this.plans = const [],
  });

  /// Smallest cover URL — legacy string-only callers.
  String? get imageUrl => coverImage?.displayUrl;
}
