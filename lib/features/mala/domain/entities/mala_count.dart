import 'package:equatable/equatable.dart';

/// The current user's lifetime count for one accumulator.
///
/// Maps to the user-owned accumulator (`GET/POST/PUT /accumulators/user`),
/// where [total] is its `current_count` and [accumulatorId] is the user
/// accumulator id (distinct from the preset id).
class MalaCount extends Equatable {
  /// The user-owned accumulator id. Null before the user's accumulator has
  /// been created (lazy-created on first sync).
  final String? accumulatorId;

  /// The mantra this count is for (links to the preset / content).
  final String? mantraId;

  /// Lifetime `current_count`.
  final int total;

  /// Per-user bead artwork (`mala_image_url`), when the user has customized it.
  /// Null falls back to the preset/mantra image.
  final String? beadImageUrl;

  final DateTime? updatedAt;

  const MalaCount({
    this.accumulatorId,
    this.mantraId,
    required this.total,
    this.beadImageUrl,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    accumulatorId,
    mantraId,
    total,
    beadImageUrl,
    updatedAt,
  ];
}
