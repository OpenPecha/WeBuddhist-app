import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_remote_datasource.dart';
import 'package:flutter_pecha/features/mala/data/models/accumulator_model.dart';
import 'package:flutter_pecha/features/mala/data/models/mantra_model.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_count.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/domain/repositories/mala_repository.dart';

class MalaRepositoryImpl implements MalaRepository {
  MalaRepositoryImpl({required this.remote, this.language});

  final MalaRemoteDataSource remote;

  /// Locale used to request mantra content (`null` returns all languages).
  final String? language;

  @override
  Future<Either<Failure, List<Mantra>>> getCatalogue() async {
    try {
      // Fetch presets and mantra content in parallel, then join by mantra_id.
      final results = await Future.wait([
        remote.fetchPresetAccumulators(),
        remote.fetchMantras(),
      ]);
      final presets = results[0] as List<AccumulatorModel>;
      final mantras = results[1] as List<MantraContentModel>;

      final contentById = {
        for (final m in mantras) m.id: m.toEntity(),
      };

      final catalogue = presets
          .map(
            (p) => Mantra(
              presetId: p.id,
              name: p.name,
              description: p.description,
              mantraId: p.mantraId,
              targetCount: p.targetCount,
              beadImageUrl: p.beadImageUrl,
              content: p.mantraId != null ? contentById[p.mantraId] : null,
            ),
          )
          .toList();
      return Right(catalogue);
    } on AppException catch (e) {
      return Left(_toFailure(e));
    } catch (e) {
      return Left(UnknownFailure('Failed to load catalogue: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MalaCount>>> getUserTotals() async {
    try {
      final user = await remote.fetchUserAccumulators();
      return Right(user.map((a) => a.toMalaCount()).toList());
    } on AppException catch (e) {
      return Left(_toFailure(e));
    } catch (e) {
      return Left(UnknownFailure('Failed to load user totals: $e'));
    }
  }

  @override
  Future<Either<Failure, MalaCount>> createUserAccumulator({
    required String name,
    String? mantraId,
    required int currentCount,
  }) async {
    try {
      final created = await remote.createUserAccumulator(
        name: name,
        mantraId: mantraId,
        currentCount: currentCount,
      );
      return Right(created.toMalaCount());
    } on AppException catch (e) {
      return Left(_toFailure(e));
    } catch (e) {
      return Left(UnknownFailure('Failed to create accumulator: $e'));
    }
  }

  @override
  Future<Either<Failure, MalaCount>> updateUserAccumulator({
    required String accumulatorId,
    required int currentCount,
  }) async {
    try {
      final updated = await remote.updateUserAccumulator(
        accumulatorId: accumulatorId,
        currentCount: currentCount,
      );
      return Right(updated.toMalaCount());
    } on AppException catch (e) {
      return Left(_toFailure(e));
    } catch (e) {
      return Left(UnknownFailure('Failed to update accumulator: $e'));
    }
  }

  Failure _toFailure(AppException e) {
    if (e is AuthenticationException) return AuthenticationFailure(e.message);
    if (e is NotFoundException) return NotFoundFailure(e.message);
    if (e is RateLimitException) return RateLimitFailure(e.message);
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is ServerException) return ServerFailure(e.message);
    return UnknownFailure(e.message);
  }
}
