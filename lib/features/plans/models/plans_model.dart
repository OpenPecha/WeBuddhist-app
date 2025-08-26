enum DifficultyLevel { beginner, intermediate, advanced }

class PlansModel {
  final String id;
  final String title;
  final String? description;
  final String? authorId;
  final String language;
  final DifficultyLevel? difficultyLevel;
  final List<String>? tags;
  final bool featured;
  final bool isActive;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PlansModel({
    required this.id,
    required this.title,
    this.description,
    this.authorId,
    required this.language,
    this.difficultyLevel,
    this.tags,
    this.featured = false,
    this.isActive = true,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory PlansModel.fromJson(Map<String, dynamic> json) {
    return PlansModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      authorId: json['author_id'],
      language: json['language'],
      difficultyLevel: DifficultyLevel.values.byName(json['difficulty_level']),
      tags: json['tags'],
      featured: json['featured'],
      isActive: json['is_active'],
      imageUrl: json['image_url'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'author_id': authorId,
      'language': language,
      'difficulty_level': difficultyLevel,
      'tags': tags,
      'featured': featured,
      'is_active': isActive,
      'image_url': imageUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
