import 'dart:convert';

import 'package:flutter_pecha/features/prayer_of_the_day/domain/entities/prayer.dart';

/// Prayer segment model with JSON serialization.
class PrayerSegmentModel {
  final String id;
  final String text;
  final String startTime; // Format: "MM:SS" or "HH:MM:SS"
  final String endTime;

  const PrayerSegmentModel({
    required this.id,
    required this.text,
    required this.startTime,
    required this.endTime,
  });

  /// Parse time string to Duration.
  static Duration _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length == 2) {
      return Duration(
        minutes: int.parse(parts[0]),
        seconds: int.parse(parts[1]),
      );
    } else if (parts.length == 3) {
      return Duration(
        hours: int.parse(parts[0]),
        minutes: int.parse(parts[1]),
        seconds: int.parse(parts[2]),
      );
    }
    return Duration.zero;
  }

  /// Format Duration to time string.
  static String _formatTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Convert PrayerSegment entity to PrayerSegmentModel.
  static PrayerSegmentModel fromEntity(PrayerSegment entity) {
    return PrayerSegmentModel(
      id: entity.id,
      text: entity.text,
      startTime: _formatTime(entity.startTime),
      endTime: _formatTime(entity.endTime),
    );
  }

  /// Convert PrayerSegmentModel to PrayerSegment entity.
  PrayerSegment toEntity() {
    return PrayerSegment(
      id: id,
      text: text,
      startTime: _parseTime(startTime),
      endTime: _parseTime(endTime),
    );
  }

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'startTime': startTime,
        'endTime': endTime,
      };

  /// Deserialize from JSON.
  factory PrayerSegmentModel.fromJson(Map<String, dynamic> json) {
    return PrayerSegmentModel(
      id: json['id'] as String? ?? '',
      text: json['text'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
    );
  }
}

/// Prayer data model with JSON serialization.
class PrayerModel {
  final String id;
  final String title;
  final String audioUrl;
  final List<PrayerSegmentModel> segments;
  final String totalDuration; // Duration in ISO 8601 format
  final DateTime date;
  final bool isCompleted;

  const PrayerModel({
    required this.id,
    required this.title,
    required this.audioUrl,
    required this.segments,
    required this.totalDuration,
    required this.date,
    this.isCompleted = false,
  });

  /// Convert Prayer entity to PrayerModel.
  static PrayerModel fromEntity(Prayer entity) {
    return PrayerModel(
      id: entity.id,
      title: entity.title,
      audioUrl: entity.audioUrl,
      segments: entity.segments.map((seg) => PrayerSegmentModel.fromEntity(seg)).toList(),
      totalDuration: _formatDuration(entity.totalDuration),
      date: entity.date,
      isCompleted: entity.isCompleted,
    );
  }

  /// Convert PrayerModel to Prayer entity.
  Prayer toEntity() {
    return Prayer(
      id: id,
      title: title,
      audioUrl: audioUrl,
      segments: segments.map((seg) => seg.toEntity()).toList(),
      totalDuration: _parseDuration(totalDuration),
      date: date,
      isCompleted: isCompleted,
    );
  }

  /// Parse ISO 8601 duration string.
  static Duration _parseDuration(String duration) {
    // Try parsing as ISO 8601 duration
    try {
      final isoDuration = RegExp(r'PT(\d+H)?(\d+M)?(\d+S)?');
      final match = isoDuration.firstMatch(duration);
      if (match != null) {
        var hours = 0;
        var minutes = 0;
        var seconds = 0;

        if (match.group(1) != null) {
          hours = int.parse(match.group(1)!.replaceAll('H', ''));
        }
        if (match.group(2) != null) {
          minutes = int.parse(match.group(2)!.replaceAll('M', ''));
        }
        if (match.group(3) != null) {
          seconds = int.parse(match.group(3)!.replaceAll('S', ''));
        }

        return Duration(hours: hours, minutes: minutes, seconds: seconds);
      }
    } catch (_) {}

    // Fallback: try parsing as simple duration
    final parts = duration.split(':');
    if (parts.length == 2) {
      return Duration(
        minutes: int.parse(parts[0]),
        seconds: int.parse(parts[1]),
      );
    } else if (parts.length == 3) {
      return Duration(
        hours: int.parse(parts[0]),
        minutes: int.parse(parts[1]),
        seconds: int.parse(parts[2]),
      );
    }

    return Duration.zero;
  }

  /// Format Duration to ISO 8601 string.
  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final buffer = StringBuffer('PT');
    if (hours > 0) buffer.write('${hours}H');
    if (minutes > 0) buffer.write('${minutes}M');
    if (seconds > 0) buffer.write('${seconds}S');

    return buffer.toString();
  }

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'audioUrl': audioUrl,
        'segments': segments.map((seg) => seg.toJson()).toList(),
        'totalDuration': totalDuration,
        'date': date.toIso8601String(),
        'isCompleted': isCompleted,
      };

  /// Deserialize from JSON.
  factory PrayerModel.fromJson(Map<String, dynamic> json) {
    return PrayerModel(
      id: json['id'] as String,
      title: json['title'] as String,
      audioUrl: json['audioUrl'] as String,
      segments: (json['segments'] as List)
          .map((seg) => PrayerSegmentModel.fromJson(seg as Map<String, dynamic>))
          .toList(),
      totalDuration: json['totalDuration'] as String? ?? 'PT0S',
      date: DateTime.parse(json['date'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  /// Deserialize from JSON string.
  factory PrayerModel.fromJsonString(String jsonString) {
    return PrayerModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Serialize to JSON string.
  String toJsonString() => jsonEncode(toJson());
}
