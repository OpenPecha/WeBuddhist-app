import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';

class AccumulatorGroupModel {
  const AccumulatorGroupModel({
    required this.groupAccumulatorId,
    required this.groupId,
    required this.userTotalCount,
    required this.isJoined,
    this.title,
    this.imageKey,
  });

  final String groupAccumulatorId;
  final String groupId;
  final String? title;
  final String? imageKey;
  final int userTotalCount;
  final bool isJoined;

  factory AccumulatorGroupModel.fromJson(Map<String, dynamic> json) {
    return AccumulatorGroupModel(
      groupAccumulatorId: json['group_accumulator_id'] as String,
      groupId: json['group_id'] as String,
      title: json['title'] as String?,
      imageKey: json['image_key'] as String?,
      userTotalCount: (json['user_total_count'] as num?)?.toInt() ?? 0,
      isJoined: json['is_joined'] as bool? ?? false,
    );
  }

  AccumulatorGroup toEntity() {
    return AccumulatorGroup(
      groupAccumulatorId: groupAccumulatorId,
      groupId: groupId,
      title: title,
      imageKey: imageKey,
      userTotalCount: userTotalCount,
      isJoined: isJoined,
    );
  }
}

class AccumulatorGroupsResponseModel {
  const AccumulatorGroupsResponseModel({
    required this.groups,
    required this.total,
  });

  final List<AccumulatorGroupModel> groups;
  final int total;

  factory AccumulatorGroupsResponseModel.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groups'] as List<dynamic>? ?? const [];
    return AccumulatorGroupsResponseModel(
      groups:
          rawGroups
              .whereType<Map<String, dynamic>>()
              .map(AccumulatorGroupModel.fromJson)
              .toList(),
      total: (json['total'] as num?)?.toInt() ?? rawGroups.length,
    );
  }
}
