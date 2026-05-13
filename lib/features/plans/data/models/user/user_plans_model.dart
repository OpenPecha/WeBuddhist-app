class UserPlansModel {
  final String id;
  final String title;
  final String description;
  final String language;
  final String? difficultyLevel;
  final String? imageUrl;
  final DateTime startedAt;
  final int totalDays;
  final List<String>? tags;
  final DateTime? startDate;

  UserPlansModel({
    required this.id,
    required this.title,
    required this.description,
    required this.language,
    required this.difficultyLevel,
    required this.imageUrl,
    required this.startedAt,
    required this.totalDays,
    required this.tags,
    this.startDate,
  });

  DateTime get effectiveStartDate => startDate ?? startedAt;

  factory UserPlansModel.fromJson(Map<String, dynamic> json) {
    return UserPlansModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      language: json['language'] as String,
      difficultyLevel: json['difficulty_level'] as String?,
      imageUrl: json['image_url'] as String?,
      startedAt: DateTime.parse(json['started_at'] as String),
      totalDays: json['total_days'] as int,
      tags:
          json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
      startDate:
          json['start_date'] != null
              ? DateTime.tryParse(json['start_date'] as String)
              : null,
      // TEMP TEST — remove before merging
      // startDate: _testStartDate(),
    );
  }

  // TEMP TEST — remove before merging
  static DateTime _testStartDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - 5);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'language': language,
      'difficulty_level': difficultyLevel,
      'image_url': imageUrl,
      'started_at': startedAt.toIso8601String(),
      'total_days': totalDays,
      'tags': tags,
      'start_date': startDate?.toIso8601String(),
    };
  }
}
