import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plans_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/domain/entities/author.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan_day.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan_progress.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/plans_repository.dart';

final _logger = AppLogger('PlansRepositoryImpl');

/// Repository implementation for managing plans.
///
/// This implements the domain repository interface and uses the remote datasource,
/// returning Either<Failure, T> results.
class PlansRepositoryImpl implements PlansRepository {
  final PlansRemoteDatasource _datasource;

  PlansRepositoryImpl({required PlansRemoteDatasource datasource})
      : _datasource = datasource;

  @override
  Future<Either<Failure, List<Plan>>> getPlans({
    required String language,
    String? search,
    String? tag,
    int? skip,
    int? limit,
  }) async {
    try {
      final models = await _datasource.fetchPlans(
        queryParams: PlansQueryParams(
          language: language,
          search: search,
          tag: tag,
          skip: skip,
          limit: limit,
        ),
      );
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      _logger.error('Failed to get plans', e);
      return Left(ExceptionMapper.map(e, context: 'getPlans'));
    }
  }

  @override
  Future<Either<Failure, Plan?>> getPlan(String id) async {
    try {
      if (id.isEmpty) {
        return const Left(ValidationFailure('Plan ID cannot be empty'));
      }
      final model = await _datasource.getPlanById(id);
      return Right(model.toEntity());
    } catch (e) {
      _logger.error('Failed to get plan $id', e);
      return Left(ExceptionMapper.map(e, context: 'getPlan'));
    }
  }

  @override
  Future<Either<Failure, List<Plan>>> getPlansByTags(List<String> tags) async {
    try {
      if (tags.isEmpty) {
        return const Right([]);
      }
      final models = await _datasource.fetchPlans(
        queryParams: PlansQueryParams(
          language: 'en',
          tag: tags.first, // API supports single tag
        ),
      );
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      _logger.error('Failed to get plans by tags', e);
      return Left(ExceptionMapper.map(e, context: 'getPlansByTags'));
    }
  }

  @override
  Future<Either<Failure, List<Plan>>> searchPlans(String query) async {
    try {
      if (query.isEmpty) {
        return const Left(ValidationFailure('Search query cannot be empty'));
      }
      final models = await _datasource.fetchPlans(
        queryParams: PlansQueryParams(
          language: 'en',
          search: query,
        ),
      );
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      _logger.error('Failed to search plans', e);
      return Left(ExceptionMapper.map(e, context: 'searchPlans'));
    }
  }

  @override
  Future<Either<Failure, List<Plan>>> getPlansByAuthor(String authorId) async {
    try {
      // The current API doesn't support filtering by author
      // We'll fetch all plans and filter locally
      final models = await _datasource.fetchPlans(
        queryParams: const PlansQueryParams(language: 'en'),
      );
      final entities = models
          .where((m) => m.author?.id == authorId)
          .map((m) => m.toEntity())
          .toList();
      return Right(entities);
    } catch (e) {
      _logger.error('Failed to get plans by author', e);
      return Left(ExceptionMapper.map(e, context: 'getPlansByAuthor'));
    }
  }

  @override
  Future<Either<Failure, Author?>> getAuthor(String authorId) async {
    try {
      // This would require an author-specific API endpoint
      // For now, return null
      return const Right(null);
    } catch (e) {
      _logger.error('Failed to get author', e);
      return Left(ExceptionMapper.map(e, context: 'getAuthor'));
    }
  }

  @override
  Future<Either<Failure, PlanProgress?>> getUserPlanProgress(String planId) async {
    try {
      // This would require a user progress API endpoint
      // For now, return null
      return const Right(null);
    } catch (e) {
      _logger.error('Failed to get user plan progress', e);
      return Left(ExceptionMapper.map(e, context: 'getUserPlanProgress'));
    }
  }

  @override
  Future<Either<Failure, PlanProgress>> enrollInPlan(String planId) async {
    try {
      // This would require an enrollment API endpoint
      // For now, return a mock progress object
      return Left(ServerFailure('Enrollment not yet implemented'));
    } catch (e) {
      _logger.error('Failed to enroll in plan', e);
      return Left(ExceptionMapper.map(e, context: 'enrollInPlan'));
    }
  }

  @override
  Future<Either<Failure, PlanProgress>> updateProgress(
    String planId,
    int dayNumber,
    String? taskId,
  ) async {
    try {
      // This would require a progress update API endpoint
      // For now, return an error
      return Left(ServerFailure('Progress update not yet implemented'));
    } catch (e) {
      _logger.error('Failed to update progress', e);
      return Left(ExceptionMapper.map(e, context: 'updateProgress'));
    }
  }

  @override
  Future<Either<Failure, void>> unenrollFromPlan(String planId) async {
    try {
      // This would require an unenrollment API endpoint
      // For now, return success
      return const Right(null);
    } catch (e) {
      _logger.error('Failed to unenroll from plan', e);
      return Left(ExceptionMapper.map(e, context: 'unenrollFromPlan'));
    }
  }

  @override
  Future<Either<Failure, PlanDay?>> getPlanDay(String planId, int dayNumber) async {
    try {
      // This would require a plan day API endpoint
      // For now, return null
      return const Right(null);
    } catch (e) {
      _logger.error('Failed to get plan day', e);
      return Left(ExceptionMapper.map(e, context: 'getPlanDay'));
    }
  }
}
