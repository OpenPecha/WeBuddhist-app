import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_remote_datasource.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_count.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/domain/repositories/mala_repository.dart';

class MalaRepositoryImpl implements MalaRepository {
  MalaRepositoryImpl({required this.remote});

  final MalaRemoteDataSource remote;

  @override
  Future<Either<Failure, List<Mantra>>> getCatalogue({
    String? language,
    String? search,
  }) async {
    try {
      final presets = await remote.fetchPresets(
        language: language,
        search: search,
      );
      return Right(presets.map((p) => p.toEntity()).toList());
    } on AppException catch (e) {
      return Left(_toFailure(e));
    } catch (e) {
      return Left(UnknownFailure('Failed to load catalogue: $e'));
    }
  }

  @override
  Future<Either<Failure, MalaCount>> getAccumulatorDetail(
    String parentId,
  ) async {
    try {
      final detail = await remote.fetchAccumulatorDetail(parentId);
      // No accumulator yet for this preset — seed at 0, lazily create later.
      return Right(detail?.toMalaCount() ?? const MalaCount(total: 0));
    } on AppException catch (e) {
      return Left(_toFailure(e));
    } catch (e) {
      return Left(UnknownFailure('Failed to load accumulator detail: $e'));
    }
  }

  @override
  Future<Either<Failure, MalaCount>> createUserAccumulator(
    String parentId,
  ) async {
    try {
      final created = await remote.createUserAccumulator(parentId);
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

  @override
  Future<Either<Failure, Unit>> deleteUserAccumulator(
    String accumulatorId,
  ) async {
    try {
      await remote.deleteUserAccumulator(accumulatorId);
      return const Right(unit);
    } on AppException catch (e) {
      return Left(_toFailure(e));
    } catch (e) {
      return Left(UnknownFailure('Failed to delete accumulator: $e'));
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
