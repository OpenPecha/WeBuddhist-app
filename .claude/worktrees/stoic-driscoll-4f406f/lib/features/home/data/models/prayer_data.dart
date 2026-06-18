import '../../domain/entities/prayer.dart';

/// PrayerData model for JSON serialization.
///
/// This handles conversion between JSON and the Prayer domain entity.
class PrayerData {
  final String text;
  final Duration startTime;
  final Duration endTime;

  PrayerData({
    required this.text,
    required this.startTime,
    required this.endTime,
  });

  factory PrayerData.fromJson(Map<String, dynamic> json) {
    return PrayerData(
      text: json['text'],
      startTime: _parseDuration(json['startTime']!),
      endTime: _parseDuration(json['endTime']!),
    );
  }

  static Duration _parseDuration(String timeStr) {
    final parts = timeStr.split(':');
    final minutes = int.parse(parts[0]);
    final seconds = int.parse(parts[1]);
    return Duration(minutes: minutes, seconds: seconds);
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'startTime': '${startTime.inMinutes}:${startTime.inSeconds % 60}',
      'endTime': '${endTime.inMinutes}:${endTime.inSeconds % 60}',
    };
  }

  /// Convert to Prayer domain entity.
  ///
  /// Note: PrayerData is a partial model (text + timestamps only).
  /// Full Prayer entities require additional fields (id, title, etc.).
  /// This method creates a minimal Prayer entity for compatibility.
  Prayer toEntity({
    required String id,
    required String title,
    String? titleTibetan,
    String? audioUrl,
    PrayerTime timeOfDay = PrayerTime.any,
  }) {
    return Prayer(
      id: id,
      title: title,
      titleTibetan: titleTibetan,
      content: text,
      audioUrl: audioUrl,
      timeOfDay: timeOfDay,
    );
  }

  /// Create PrayerData from a Prayer domain entity.
  ///
  /// Note: This extracts the timing data if available in the content,
  /// otherwise uses default values.
  factory PrayerData.fromEntity(Prayer prayer) {
    // Extract timing from prayer content if available
    // For now, use default values since Prayer entity doesn't store timestamps
    return PrayerData(
      text: prayer.content,
      startTime: Duration.zero,
      endTime: const Duration(minutes: 5),
    );
  }
}
