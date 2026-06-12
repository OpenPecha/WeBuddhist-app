import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

class SeriesGroup {
  final String id;
  final String slug;
  final bool isPublic;
  final String title;
  final String? subTitle;
  final String? description;
  final String? avatarUrl;
  final String? bannerUrl;

  const SeriesGroup({
    required this.id,
    this.slug = '',
    this.isPublic = false,
    this.title = '',
    this.subTitle,
    this.description,
    this.avatarUrl,
    this.bannerUrl,
  });
}

class Series {
  final String id;
  final String title;
  final String? subTitle;
  final String description;
  final ResponsiveImage? coverImage;
  final bool featured;
  final int totalDays;
  final List<Plan> plans;
  final SeriesGroup? group;

  const Series({
    required this.id,
    required this.title,
    this.subTitle,
    required this.description,
    this.coverImage,
    this.featured = false,
    this.totalDays = 0,
    this.plans = const [],
    this.group,
  });

  /// Smallest cover URL — legacy string-only callers.
  String? get imageUrl => coverImage?.displayUrl;
}
