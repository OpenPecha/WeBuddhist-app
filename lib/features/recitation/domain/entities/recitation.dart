import 'package:flutter_pecha/shared/domain/entities/base_entity.dart';
import 'package:flutter_pecha/features/recitation/domain/content_type.dart';

/// Recitation entity.
class Recitation extends BaseEntity {
  final String id;
  final String title;
  final String? titleTibetan;
  final String reciterName;
  final Duration duration;
  final String? audioUrl;
  final ContentType contentType;
  final String? textId; // Associated text ID

  const Recitation({
    required this.id,
    required this.title,
    this.titleTibetan,
    required this.reciterName,
    required this.duration,
    this.audioUrl,
    required this.contentType,
    this.textId,
  });

  String getDisplayTitle(bool preferTibetan) {
    if (preferTibetan && titleTibetan != null && titleTibetan!.isNotEmpty) {
      return titleTibetan!;
    }
    return title;
  }

  @override
  List<Object?> get props => [id, title, titleTibetan, reciterName, duration, audioUrl, contentType, textId];
}
