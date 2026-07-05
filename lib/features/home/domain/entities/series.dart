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

class SeriesProgress {
  final int totalDayCount;
  final int currentDayNumber;

  const SeriesProgress({
    required this.totalDayCount,
    required this.currentDayNumber,
  });

  /// 0..1 completion ratio, safe against zero/overflowing day counts.
  double get fraction {
    if (totalDayCount <= 0) return 0;
    return (currentDayNumber / totalDayCount).clamp(0.0, 1.0);
  }
}

class SeriesPartner {
  final String groupName;
  final String? groupImage;

  const SeriesPartner({required this.groupName, this.groupImage});
}

class Series {
  final String id;
  final String title;
  final String? subTitle;
  final String description;
  final ResponsiveImage? coverImage;
  final bool featured;
  final int totalDays;
  final int planCount;
  final int enrolledCount;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<Plan> plans;
  final SeriesGroup? group;
  final SeriesProgress? progress;
  final SeriesPartner? partner;

  const Series({
    required this.id,
    required this.title,
    this.subTitle,
    required this.description,
    this.coverImage,
    this.featured = false,
    this.totalDays = 0,
    this.planCount = 0,
    this.enrolledCount = 0,
    this.startDate,
    this.endDate,
    this.plans = const [],
    this.group,
    this.progress,
    this.partner,
  });

  /// Smallest cover URL — legacy string-only callers.
  String? get imageUrl => coverImage?.displayUrl;

  /// True when list/metadata cache has [planCount] but the detail [plans]
  /// payload has not been loaded yet.
  bool get isPlansPayloadPending => plans.isEmpty && planCount > 0;
}
