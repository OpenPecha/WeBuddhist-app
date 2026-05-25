import 'package:flutter_pecha/features/plans/data/models/plan_tag_model.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';

export 'package:flutter_pecha/features/plans/data/models/plan_tag_model.dart';

class UserPlansModel {
  final String id;
  final String title;
  final String description;
  final String language;
  final String? difficultyLevel;
  final String? imageUrl;
  final DateTime startedAt;
  final int totalDays;
  final List<PlanTag>? tags;
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
      startedAt:
          json['started_at'] != null
              ? DateTime.parse(json['started_at'] as String)
              : DateTime.now(),
      totalDays: json['total_days'] as int,
      tags:
          json['tags'] != null
              ? (json['tags'] as List)
                  .map((t) => PlanTag.fromJson(t as Map<String, dynamic>))
                  .toList()
              : null,
      startDate: PlanUtils.parseCalendarDate(json['start_date'] as String?),
    );
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
      'tags': tags?.map((t) => t.toJson()).toList(),
      'start_date': startDate?.toIso8601String(),
    };
  }
}
