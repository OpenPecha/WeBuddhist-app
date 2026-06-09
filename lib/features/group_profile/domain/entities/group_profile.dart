import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

class GroupProfileSocialLink {
  final String id;
  final String platform;
  final String url;

  const GroupProfileSocialLink({
    required this.id,
    required this.platform,
    required this.url,
  });
}

class GroupProfileSeries {
  final String id;
  final String title;
  final String? subTitle;
  final String? description;
  final ResponsiveImage? image;
  final bool featured;
  final int planCount;
  final int totalDays;

  const GroupProfileSeries({
    required this.id,
    required this.title,
    this.subTitle,
    this.description,
    this.image,
    this.featured = false,
    this.planCount = 0,
    this.totalDays = 0,
  });
}

class GroupProfile {
  final String id;
  final String slug;
  final bool isPublic;
  final String title;
  final String? subTitle;
  final String? description;
  final String? avatarUrl;
  final String? bannerUrl;
  final List<String> tags;
  final List<GroupProfileSocialLink> socialLinks;
  final List<GroupProfileSeries> series;

  const GroupProfile({
    required this.id,
    this.slug = '',
    this.isPublic = false,
    this.title = '',
    this.subTitle,
    this.description,
    this.avatarUrl,
    this.bannerUrl,
    this.tags = const [],
    this.socialLinks = const [],
    this.series = const [],
  });
}
