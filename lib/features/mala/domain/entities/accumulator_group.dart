import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

/// A group accumulator linked to a preset, from
/// `GET /accumulators/{accumulator_id}/groups`.
class AccumulatorGroup extends Equatable {
  const AccumulatorGroup({
    required this.groupAccumulatorId,
    required this.groupId,
    required this.userTotalCount,
    required this.isJoined,
    this.title,
    this.image,
  });

  final String groupAccumulatorId;
  final String groupId;
  final String? title;
  final ResponsiveImage? image;
  /// User's total for this group accumulator (`user_total_count` from API).
  final int userTotalCount;
  final bool isJoined;

  @override
  List<Object?> get props => [
    groupAccumulatorId,
    groupId,
    title,
    image,
    userTotalCount,
    isJoined,
  ];
}
