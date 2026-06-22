import 'package:equatable/equatable.dart';

class SeriesDayCompleted extends Equatable {
  final String seriesId;
  final String seriesTitle;
  final String? imageUrl;
  final int daysCompleted;

  const SeriesDayCompleted({
    required this.seriesId,
    required this.seriesTitle,
    this.imageUrl,
    required this.daysCompleted,
  });

  @override
  List<Object?> get props => [seriesId, seriesTitle, imageUrl, daysCompleted];
}

class SeriesDayCompletedPage extends Equatable {
  final List<SeriesDayCompleted> series;
  final int total;

  const SeriesDayCompletedPage({
    required this.series,
    required this.total,
  });

  static const empty = SeriesDayCompletedPage(series: [], total: 0);

  @override
  List<Object?> get props => [series, total];
}
