import 'package:flutter_pecha/shared/domain/entities/base_entity.dart';

/// Prayer entity for daily prayers.
class Prayer extends BaseEntity {
  final String id;
  final String title;
  final String? titleTibetan;
  final String content;
  final String? audioUrl;
  final PrayerTime timeOfDay;

  const Prayer({
    required this.id,
    required this.title,
    this.titleTibetan,
    required this.content,
    this.audioUrl,
    required this.timeOfDay,
  });

  String getDisplayTitle(bool preferTibetan) {
    if (preferTibetan && titleTibetan != null && titleTibetan!.isNotEmpty) {
      return titleTibetan!;
    }
    return title;
  }

  @override
  List<Object?> get props => [id, title, titleTibetan, content, audioUrl, timeOfDay];
}

enum PrayerTime { morning, afternoon, evening, any }
