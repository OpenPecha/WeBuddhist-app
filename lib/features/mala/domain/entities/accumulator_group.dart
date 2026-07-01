import 'package:equatable/equatable.dart';

/// A group accumulator linked to a preset, from
/// `GET /accumulators/{accumulator_id}/groups`.
class AccumulatorGroup extends Equatable {
  const AccumulatorGroup({
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

  @override
  List<Object?> get props => [
    groupAccumulatorId,
    groupId,
    title,
    imageKey,
    userTotalCount,
    isJoined,
  ];
}
