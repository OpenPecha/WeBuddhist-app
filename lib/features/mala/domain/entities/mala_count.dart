import 'package:equatable/equatable.dart';

/// The current user's counts for one accumulator preset.
///
/// Maps to the user-owned accumulator (`GET/POST/PUT /accumulators/user`) and
/// `GET /accumulators/{parent_id}` detail, where [total] is the active session
/// `current_count`, [totalCounted] is lifetime `total_counted`, and
/// [accumulatorId] is the user accumulator id (distinct from the preset id).
class MalaCount extends Equatable {
  /// The user-owned accumulator id. Null before the user's accumulator has
  /// been created (lazy-created on first sync).
  final String? accumulatorId;

  /// The mantra this count is for (links to the preset / content).
  final String? mantraId;

  /// Active session `current_count`.
  final int total;

  /// Lifetime `total_counted` across all sessions for this preset.
  final int totalCounted;

  /// Per-user bead artwork (`mala_image_url`), when the user has customized it.
  /// Null falls back to the preset/mantra image.
  final String? beadImageUrl;

  final DateTime? updatedAt;

  const MalaCount({
    this.accumulatorId,
    this.mantraId,
    required this.total,
    this.totalCounted = 0,
    this.beadImageUrl,
    this.updatedAt,
  });

  @override
  List<Object?> get props =>
      [accumulatorId, mantraId, total, totalCounted, beadImageUrl, updatedAt];
}
