import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/plans/data/models/plans_model.dart';

class SeriesMetadataModel {
  final String id;
  final String title;
  final String? subTitle;
  final String description;
  final String language;

  SeriesMetadataModel({
    required this.id,
    required this.title,
    this.subTitle,
    required this.description,
    required this.language,
  });

  factory SeriesMetadataModel.fromJson(Map<String, dynamic> json) {
    return SeriesMetadataModel(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      subTitle: json['sub_title'] as String?,
      description: (json['description'] as String?) ?? '',
      language: (json['language'] as String?) ?? '',
    );
  }
}

class SeriesModel {
  final String id;
  final List<SeriesMetadataModel> metadataList;
  final ImageModel? image;
  final String authorId;
  final bool featured;
  final String? status;
  final int? planCount;
  final List<PlansModel> plans;
  final int totalDays;

  SeriesModel({
    required this.id,
    this.metadataList = const [],
    this.image,
    this.authorId = '',
    this.featured = false,
    this.status,
    this.planCount,
    this.plans = const [],
    this.totalDays = 0,
  });

  String? get imageUrl => image?.displayUrl;

  SeriesMetadataModel? resolveMetadata(String language) {
    if (metadataList.isEmpty) return null;
    final upper = language.toUpperCase();
    return metadataList.cast<SeriesMetadataModel?>().firstWhere(
          (m) => m!.language.toUpperCase() == upper,
          orElse: () =>
              metadataList.cast<SeriesMetadataModel?>().firstWhere(
                (m) => m!.language.toUpperCase() == 'EN',
                orElse: () => metadataList.first,
              ),
        );
  }

  factory SeriesModel.fromJson(Map<String, dynamic> json) {
    final metadataJson = json['metadata'];
    final List<SeriesMetadataModel> metadataList;
    if (metadataJson is List) {
      metadataList =
          metadataJson
              .whereType<Map<String, dynamic>>()
              .map(SeriesMetadataModel.fromJson)
              .toList();
    } else if (metadataJson is Map<String, dynamic>) {
      metadataList = [SeriesMetadataModel.fromJson(metadataJson)];
    } else {
      metadataList = const [];
    }

    final plansList =
        (json['plans'] as List<dynamic>? ?? [])
            .map((p) => PlansModel.fromJson(p as Map<String, dynamic>))
            .toList();

    return SeriesModel(
      id: json['id'] as String,
      metadataList: metadataList,
      image: ImageModel.fromJsonMap(json),
      authorId: json['author_id'] as String? ?? '',
      featured: json['featured'] as bool? ?? false,
      status: json['status'] as String?,
      planCount: (json['plan_count'] as num?)?.toInt(),
      plans: plansList,
      totalDays: (json['total_days'] as num?)?.toInt() ?? 0,
    );
  }

  Series toEntity({String language = 'en'}) {
    final resolved = resolveMetadata(language);
    return Series(
      id: id,
      title: resolved?.title ?? '',
      description: resolved?.description ?? '',
      coverImage: image?.toResponsiveImage(),
      featured: featured,
      totalDays: totalDays,
      plans: plans.map((p) => p.toEntity()).toList(),
    );
  }
}
