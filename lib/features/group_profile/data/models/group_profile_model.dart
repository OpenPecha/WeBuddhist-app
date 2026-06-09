import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

class GroupProfileModel {
  final String id;
  final String slug;
  final bool isPublic;
  final String? avatarUrl;
  final String? bannerUrl;
  final bool isFollowing;
  final Map<String, dynamic>? metadata;
  final List<String> tags;
  final List<Map<String, dynamic>> socialLinksJson;
  final List<Map<String, dynamic>> seriesJson;

  GroupProfileModel({
    required this.id,
    this.slug = '',
    this.isPublic = false,
    this.avatarUrl,
    this.bannerUrl,
    this.isFollowing = false,
    this.metadata,
    this.tags = const [],
    this.socialLinksJson = const [],
    this.seriesJson = const [],
  });

  factory GroupProfileModel.fromJson(Map<String, dynamic> json) {
    return GroupProfileModel(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      isPublic: json['is_public'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      isFollowing: json['is_following'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toList() ??
          const [],
      socialLinksJson: (json['social_links'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          const [],
      seriesJson: (json['series'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          const [],
    );
  }

  GroupProfile toEntity() {
    return GroupProfile(
      id: id,
      slug: slug,
      isPublic: isPublic,
      title: metadata?['title'] as String? ?? '',
      subTitle: metadata?['sub_title'] as String?,
      description: metadata?['description'] as String?,
      avatarUrl: avatarUrl,
      bannerUrl: bannerUrl,
      isFollowing: isFollowing,
      tags: tags,
      socialLinks: socialLinksJson.map(_parseSocialLink).toList(),
      series: seriesJson.map(_parseSeries).toList(),
    );
  }

  GroupProfileSocialLink _parseSocialLink(Map<String, dynamic> json) {
    return GroupProfileSocialLink(
      id: json['id'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  GroupProfileSeries _parseSeries(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>?;
    final imageJson = json['image'] as Map<String, dynamic>?;

    return GroupProfileSeries(
      id: json['id'] as String? ?? '',
      title: meta?['title'] as String? ?? '',
      subTitle: meta?['sub_title'] as String?,
      description: meta?['description'] as String?,
      image: imageJson != null ? ResponsiveImage.fromJson(imageJson) : null,
      featured: json['featured'] as bool? ?? false,
      planCount: (json['plan_count'] as num?)?.toInt() ?? 0,
      totalDays: (json['total_days'] as num?)?.toInt() ?? 0,
    );
  }
}
