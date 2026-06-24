import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_count.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';

abstract class MalaRepository {
  /// Preset accumulators (catalogue), from `GET /accumulators/presets`.
  /// [language] localizes the embedded mantra title/text/pronunciation.
  Future<Either<Failure, List<Mantra>>> getCatalogue({String? language});

  /// The user's detail for one preset, from `GET /accumulators/{parent_id}`.
  /// Returns a count of 0 with a null `accumulatorId` when the user has no
  /// accumulator for this preset yet. Used to seed before counting.
  Future<Either<Failure, MalaCount>> getAccumulatorDetail(String parentId);

  /// Create the user's accumulator for a preset (`POST /accumulators/user`,
  /// body `{parent_id}`). The new accumulator starts at count 0; the caller
  /// then pushes the absolute total via [updateUserAccumulator].
  Future<Either<Failure, MalaCount>> createUserAccumulator(String parentId);

  /// Push the absolute lifetime [currentCount] for an existing user
  /// accumulator (`PUT /accumulators/user/{id}`). Returns the stored count.
  Future<Either<Failure, MalaCount>> updateUserAccumulator({
    required String accumulatorId,
    required int currentCount,
  });

  /// Soft-delete a user accumulator (`DELETE /accumulators/user/{id}`).
  /// Used when resetting the on-screen session while preserving lifetime totals
  /// on the deleted record server-side.
  Future<Either<Failure, Unit>> deleteUserAccumulator(String accumulatorId);
}
