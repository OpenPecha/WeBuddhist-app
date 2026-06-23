import 'package:flutter_pecha/features/more/domain/entities/series_day_completed.dart';
import 'package:flutter_pecha/features/plans/data/models/plans_model.dart';

class SeriesDayCompletedPageModel {
  final List<SeriesDayCompletedModel> series;
  final int total;

  const SeriesDayCompletedPageModel({
    required this.series,
    required this.total,
  });

  factory SeriesDayCompletedPageModel.fromJson(Map<String, dynamic> json) {
    final seriesJson = json['series'] as List<dynamic>? ?? const [];
    return SeriesDayCompletedPageModel(
      series: seriesJson
          .whereType<Map<String, dynamic>>()
          .map(SeriesDayCompletedModel.fromJson)
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  SeriesDayCompletedPage toEntity() {
    return SeriesDayCompletedPage(
      series: series.map((item) => item.toEntity()).toList(),
      total: total,
    );
  }
}

class SeriesDayCompletedModel {
  final String seriesId;
  final String seriesTitle;
  final ImageModel? image;
  final int daysCompleted;

  const SeriesDayCompletedModel({
    required this.seriesId,
    required this.seriesTitle,
    this.image,
    required this.daysCompleted,
  });

  factory SeriesDayCompletedModel.fromJson(Map<String, dynamic> json) {
    return SeriesDayCompletedModel(
      seriesId: json['series_id'] as String? ?? '',
      seriesTitle: json['series_title'] as String? ?? '',
      image: ImageModel.fromJsonMap(json),
      daysCompleted: (json['days_completed'] as num?)?.toInt() ?? 0,
    );
  }

  SeriesDayCompleted toEntity() {
    return SeriesDayCompleted(
      seriesId: seriesId,
      seriesTitle: seriesTitle,
      imageUrl: image?.displayUrl,
      daysCompleted: daysCompleted,
    );
  }
}
