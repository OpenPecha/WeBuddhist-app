import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/shared/domain/entities/base_entity.dart';

/// Prayer segment entity with text and timing information.
class PrayerSegment extends Equatable {
  final String id;
  final String text;
  final Duration startTime;
  final Duration endTime;

  const PrayerSegment({
    required this.id,
    required this.text,
    required this.startTime,
    required this.endTime,
  });

  @override
  List<Object?> get props => [id, text, startTime, endTime];
}

/// Prayer entity for prayer of the day feature.
class Prayer extends BaseEntity {
  final String id;
  final String title;
  final String audioUrl;
  final List<PrayerSegment> segments;
  final Duration totalDuration;
  final DateTime date;
  final bool isCompleted;

  const Prayer({
    required this.id,
    required this.title,
    required this.audioUrl,
    required this.segments,
    required this.totalDuration,
    required this.date,
    this.isCompleted = false,
  });

  /// Get the segment that should be highlighted at the given position.
  PrayerSegment? getSegmentAtPosition(Duration position) {
    for (final segment in segments) {
      if (position >= segment.startTime && position < segment.endTime) {
        return segment;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        audioUrl,
        segments,
        totalDuration,
        date,
        isCompleted,
      ];
}
