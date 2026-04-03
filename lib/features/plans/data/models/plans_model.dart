import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/plans/data/models/author/author_dto_model.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart'
    as domain;

final _logger = AppLogger('PlansModel');

enum DifficultyLevel { beginner, intermediate, advanced }

/// Model for plan image with different sizes
class ImageModel {
  final String? thumbnail;
  final String? medium;
  final String? original;

  ImageModel({this.thumbnail, this.medium, this.original});

  factory ImageModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ImageModel();
    return ImageModel(
      thumbnail: json['thumbnail'] as String?,
      medium: json['medium'] as String?,
      original: json['original'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'thumbnail': thumbnail, 'medium': medium, 'original': original};
  }
}

class PlansModel {
  final String id;
  final String title;
  final String description;
  final String language;
  final String? difficultyLevel;
  final ImageModel? image;
  final int? totalDays;
  final List<String>? tags;
  final AuthorDtoModel? author;

  PlansModel({
    required this.id,
    required this.title,
    required this.description,
    required this.language,
    this.difficultyLevel,
    this.image,
    this.totalDays,
    this.tags,
    this.author,
  });

  /// Backward compatibility getter - returns medium image or original as fallback
  String? get imageUrl => image?.medium ?? image?.original;
  String? get imageThumbnail => image?.thumbnail ?? image?.medium;

  factory PlansModel.fromJson(Map<String, dynamic> json) {
    try {
      // Handle both old format (image_url) and new format (image object)
      ImageModel? imageModel;
      if (json['image'] != null) {
        imageModel = ImageModel.fromJson(
          json['image'] as Map<String, dynamic>?,
        );
      } else if (json['image_url'] != null) {
        // Backward compatibility: convert old string format to new model
        final imageUrl = json['image_url'] as String?;
        if (imageUrl != null) {
          imageModel = ImageModel(
            thumbnail: imageUrl,
            medium: imageUrl,
            original: imageUrl,
          );
        }
      }

      return PlansModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        language: json['language'] as String,
        difficultyLevel: json['difficulty_level'] as String?,
        image: imageModel,
        totalDays: json['total_days'] as int?,
        tags:
            json['tags'] != null
                ? List<String>.from(json['tags'] as List)
                : null,
        author:
            json['author'] != null
                ? AuthorDtoModel.fromJson(
                  json['author'] as Map<String, dynamic>,
                )
                : null,
      );
    } catch (e) {
      _logger.error('Error in PlansModel.fromJson', e);
      throw Exception('Failed to load plans: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'language': language,
      'difficulty_level': difficultyLevel,
      'image': image?.toJson(),
      'total_days': totalDays ?? 0,
      'tags': tags,
    };
  }

  /// Create a copy of this plan with optional field updates
  PlansModel copyWith({
    String? id,
    String? title,
    String? description,
    String? language,
    String? difficultyLevel,
    ImageModel? image,
    int? totalDays,
    List<String>? tags,
  }) {
    return PlansModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      language: language ?? this.language,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      image: image ?? this.image,
      totalDays: totalDays ?? this.totalDays,
      tags: tags ?? this.tags,
      author: author,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlansModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PlansModel(id: $id, title: $title, language: $language, totalDays: $totalDays)';
  }

  /// Convert to Plan domain entity.
  domain.Plan toEntity() {
    // Map difficulty level string to enum
    domain.DifficultyLevel difficulty;
    switch (difficultyLevel?.toLowerCase()) {
      case 'beginner':
        difficulty = domain.DifficultyLevel.beginner;
        break;
      case 'intermediate':
        difficulty = domain.DifficultyLevel.intermediate;
        break;
      case 'advanced':
        difficulty = domain.DifficultyLevel.advanced;
        break;
      case 'all':
      default:
        difficulty = domain.DifficultyLevel.allLevels;
    }

    return domain.Plan(
      id: id,
      title: title,
      titleTibetan: null, // Not available in the model
      description: description,
      authorId: author?.id ?? '',
      authorName: author?.firstName ?? 'Unknown',
      coverImageUrl: imageUrl,
      totalDays: totalDays ?? 0,
      difficulty: difficulty,
      tags: tags ?? [],
      weekPlans: const [], // Will be populated by separate call if needed
      language: language,
    );
  }

  /// Create PlansModel from a Plan domain entity.
  factory PlansModel.fromEntity(domain.Plan entity) {
    // Map difficulty level enum to string
    String? difficultyLevelStr;
    switch (entity.difficulty) {
      case domain.DifficultyLevel.beginner:
        difficultyLevelStr = 'beginner';
        break;
      case domain.DifficultyLevel.intermediate:
        difficultyLevelStr = 'intermediate';
        break;
      case domain.DifficultyLevel.advanced:
        difficultyLevelStr = 'advanced';
        break;
      case domain.DifficultyLevel.allLevels:
        difficultyLevelStr = 'all';
        break;
    }

    return PlansModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      language: entity.language,
      difficultyLevel: difficultyLevelStr,
      image:
          entity.coverImageUrl != null
              ? ImageModel(
                thumbnail: entity.coverImageUrl,
                medium: entity.coverImageUrl,
                original: entity.coverImageUrl,
              )
              : null,
      totalDays: entity.totalDays,
      tags: entity.tags,
      author:
          entity.authorId.isNotEmpty
              ? AuthorDtoModel(
                id: entity.authorId,
                firstName: entity.authorName ?? 'Unknown',
                lastName: '',
              )
              : null,
    );
  }
}
