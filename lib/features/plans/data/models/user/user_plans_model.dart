import 'package:flutter_pecha/features/plans/data/models/plan_tag_model.dart';
import 'package:flutter_pecha/features/plans/data/models/plans_model.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';

export 'package:flutter_pecha/features/plans/data/models/plan_tag_model.dart';

class UserPlansModel {
  final String id;
  final String title;
  final String description;
  final String language;
  final String? difficultyLevel;
  final ImageModel? image;
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
    this.image,
    required this.startedAt,
    required this.totalDays,
    required this.tags,
    this.startDate,
  });

  DateTime get effectiveStartDate => startDate ?? startedAt;

  String? get imageUrl => image?.displayUrl;

  factory UserPlansModel.fromJson(Map<String, dynamic> json) {
    return UserPlansModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      language: json['language'] as String,
      difficultyLevel: json['difficulty_level'] as String?,
      image: ImageModel.fromJsonMap(json),
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
      'image': image?.toJson(),
      'image_url': imageUrl,
      'started_at': startedAt.toIso8601String(),
      'total_days': totalDays,
      'tags': tags?.map((t) => t.toJson()).toList(),
      'start_date': startDate?.toIso8601String(),
    };
  }
}
