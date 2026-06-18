import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/shared/domain/entities/base_entity.dart';

/// Story entity for story view feature.
class Story extends BaseEntity {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final List<StorySlide> slides;
  final StoryType type;
  final DateTime createdAt;

  const Story({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.slides = const [],
    required this.type,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, title, description, imageUrl, slides, type, createdAt];
}

/// Story slide entity.
class StorySlide extends Equatable {
  final String id;
  final String? imageUrl;
  final String? text;
  final String? videoUrl;
  final int duration; // in seconds
  final SlideType type;

  const StorySlide({
    required this.id,
    this.imageUrl,
    this.text,
    this.videoUrl,
    this.duration = 5,
    required this.type,
  });

  @override
  List<Object?> get props => [id, imageUrl, text, videoUrl, duration, type];
}

enum StoryType { plan, author, event, promotion }
enum SlideType { image, video, text }
