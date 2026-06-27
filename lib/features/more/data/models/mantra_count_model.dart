import 'package:flutter_pecha/features/more/domain/entities/mantra_count.dart';

class MantraCountPageModel {
  final List<MantraCountModel> counts;

  const MantraCountPageModel({required this.counts});

  factory MantraCountPageModel.fromJson(Map<String, dynamic> json) {
    final countsJson = json['counts'] as List<dynamic>? ?? const [];
    return MantraCountPageModel(
      counts:
          countsJson
              .whereType<Map<String, dynamic>>()
              .map(MantraCountModel.fromJson)
              .toList(),
    );
  }

  MantraCountPage toEntity() {
    return MantraCountPage(
      counts: counts.map((item) => item.toEntity()).toList(),
    );
  }
}

class MantraCountModel {
  final String mantraId;
  final String mantraTitle;
  final String? malaImageUrl;
  final int totalCount;

  const MantraCountModel({
    required this.mantraId,
    required this.mantraTitle,
    this.malaImageUrl,
    required this.totalCount,
  });

  factory MantraCountModel.fromJson(Map<String, dynamic> json) {
    return MantraCountModel(
      mantraId: json['mantra_id'] as String? ?? '',
      mantraTitle: json['mantra_title'] as String? ?? '',
      malaImageUrl: json['mala_image_url'] as String?,
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
    );
  }

  MantraCount toEntity() {
    return MantraCount(
      mantraId: mantraId,
      mantraTitle: mantraTitle,
      malaImageUrl: malaImageUrl,
      totalCount: totalCount,
    );
  }
}
