import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_count.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';

abstract class MalaRepository {
  /// Preset accumulators joined with their localized mantra content,
  /// from `GET /accumulators` + `GET /mantra`.
  Future<Either<Failure, List<Mantra>>> getCatalogue();

  /// All of the current user's accumulators with their lifetime counts,
  /// from `GET /accumulators/user`. Used to seed before counting.
  Future<Either<Failure, List<MalaCount>>> getUserTotals();

  /// Lazily create the user's own accumulator for a preset
  /// (`POST /accumulators/user`). Returns the created count with its new id.
  Future<Either<Failure, MalaCount>> createUserAccumulator({
    required String name,
    String? mantraId,
    required int currentCount,
  });

  /// Send the absolute lifetime [currentCount] for an existing user
  /// accumulator (`PUT /accumulators/user/{id}`). Returns the stored count.
  Future<Either<Failure, MalaCount>> updateUserAccumulator({
    required String accumulatorId,
    required int currentCount,
  });
}
