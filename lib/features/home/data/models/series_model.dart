import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/plans/data/models/plans_model.dart';

class SeriesMetadataModel {
  final String id;
  final String title;
  final String description;
  final String language;

  SeriesMetadataModel({
    required this.id,
    required this.title,
    required this.description,
    required this.language,
  });

  factory SeriesMetadataModel.fromJson(Map<String, dynamic> json) {
    return SeriesMetadataModel(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      language: (json['language'] as String?) ?? '',
    );
  }
}

class SeriesModel {
  final String id;
  final List<SeriesMetadataModel> metadata;
  final ImageModel? image;
  final String authorId;
  final bool featured;
  final String? status;
  final int? planCount;
  final List<PlansModel> plans;
  final int totalDays;

  SeriesModel({
    required this.id,
    required this.metadata,
    this.image,
    this.authorId = '',
    this.featured = false,
    this.status,
    this.planCount,
    this.plans = const [],
    this.totalDays = 0,
  });

  String? get imageUrl => image?.displayUrl;

  factory SeriesModel.fromJson(Map<String, dynamic> json) {
    final metadataList =
        (json['metadata'] as List<dynamic>? ?? [])
            .map((m) => SeriesMetadataModel.fromJson(m as Map<String, dynamic>))
            .toList();

    final plansList =
        (json['plans'] as List<dynamic>? ?? [])
            .map((p) => PlansModel.fromJson(p as Map<String, dynamic>))
            .toList();

    return SeriesModel(
      id: json['id'] as String,
      metadata: metadataList,
      image: ImageModel.fromJsonMap(json),
      authorId: json['author_id'] as String? ?? '',
      featured: json['featured'] as bool? ?? false,
      status: json['status'] as String?,
      planCount: (json['plan_count'] as num?)?.toInt(),
      plans: plansList,
      totalDays: (json['total_days'] as num?)?.toInt() ?? 0,
    );
  }

  /// Pick metadata for [activeLanguageCode] (e.g. 'en' → 'EN'), falling back
  /// to 'EN', then to the first available entry. Returns empty strings if
  /// no metadata exists at all.
  SeriesMetadataModel? _pickMetadata(String activeLanguageCode) {
    if (metadata.isEmpty) return null;
    final target = activeLanguageCode.toUpperCase();
    for (final m in metadata) {
      if (m.language.toUpperCase() == target) return m;
    }
    for (final m in metadata) {
      if (m.language.toUpperCase() == 'EN') return m;
    }
    return metadata.first;
  }

  Series toEntity(String activeLanguageCode) {
    final picked = _pickMetadata(activeLanguageCode);
    return Series(
      id: id,
      title: picked?.title ?? '',
      description: picked?.description ?? '',
      imageUrl: imageUrl,
      featured: featured,
      totalDays: totalDays,
      plans: plans.map((p) => p.toEntity()).toList(),
    );
  }
}
