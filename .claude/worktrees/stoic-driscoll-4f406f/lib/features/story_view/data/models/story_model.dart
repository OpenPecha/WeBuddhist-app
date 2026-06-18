import 'dart:convert';

import 'package:flutter_pecha/features/story_view/domain/entities/story.dart';

/// Story slide data model with JSON serialization.
class StorySlideModel {
  final String id;
  final String? imageUrl;
  final String? text;
  final String? videoUrl;
  final int duration; // in seconds
  final SlideType type;

  const StorySlideModel({
    required this.id,
    this.imageUrl,
    this.text,
    this.videoUrl,
    this.duration = 5,
    required this.type,
  });

  /// Convert StorySlide entity to StorySlideModel.
  static StorySlideModel fromEntity(StorySlide entity) {
    return StorySlideModel(
      id: entity.id,
      imageUrl: entity.imageUrl,
      text: entity.text,
      videoUrl: entity.videoUrl,
      duration: entity.duration,
      type: entity.type,
    );
  }

  /// Convert StorySlideModel to StorySlide entity.
  StorySlide toEntity() {
    return StorySlide(
      id: id,
      imageUrl: imageUrl,
      text: text,
      videoUrl: videoUrl,
      duration: duration,
      type: type,
    );
  }

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'imageUrl': imageUrl,
        'text': text,
        'videoUrl': videoUrl,
        'duration': duration,
        'type': type.name,
      };

  /// Deserialize from JSON.
  factory StorySlideModel.fromJson(Map<String, dynamic> json) {
    return StorySlideModel(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String?,
      text: json['text'] as String?,
      videoUrl: json['videoUrl'] as String?,
      duration: json['duration'] as int? ?? 5,
      type: SlideType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SlideType.image,
      ),
    );
  }
}

/// Story data model with JSON serialization.
class StoryModel {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final List<StorySlideModel> slides;
  final StoryType type;
  final DateTime createdAt;

  const StoryModel({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.slides = const [],
    required this.type,
    required this.createdAt,
  });

  /// Convert Story entity to StoryModel.
  static StoryModel fromEntity(Story entity) {
    return StoryModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      imageUrl: entity.imageUrl,
      slides: entity.slides.map((slide) => StorySlideModel.fromEntity(slide)).toList(),
      type: entity.type,
      createdAt: entity.createdAt,
    );
  }

  /// Convert StoryModel to Story entity.
  Story toEntity() {
    return Story(
      id: id,
      title: title,
      description: description,
      imageUrl: imageUrl,
      slides: slides.map((slide) => slide.toEntity()).toList(),
      type: type,
      createdAt: createdAt,
    );
  }

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'slides': slides.map((slide) => slide.toJson()).toList(),
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Deserialize from JSON.
  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      slides: (json['slides'] as List?)
              ?.map((slide) => StorySlideModel.fromJson(slide as Map<String, dynamic>))
              .toList() ??
          [],
      type: StoryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => StoryType.promotion,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Serialize to JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize from JSON string.
  factory StoryModel.fromJsonString(String jsonString) {
    return StoryModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
