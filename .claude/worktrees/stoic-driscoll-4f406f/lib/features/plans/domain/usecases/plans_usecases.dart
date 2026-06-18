import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan_progress.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/plans_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Get plans use case with pagination and filtering support.
class GetPlansUseCase extends UseCase<List<Plan>, GetPlansParams> {
  final PlansRepository _repository;

  GetPlansUseCase(this._repository);

  @override
  Future<Either<Failure, List<Plan>>> call(GetPlansParams params) async {
    return await _repository.getPlans(
      language: params.language,
      search: params.search,
      tag: params.tag,
      skip: params.skip,
      limit: params.limit,
    );
  }
}

/// Parameters for GetPlansUseCase with pagination and filtering support.
class GetPlansParams extends Equatable {
  final String language;
  final String? search;
  final String? tag;
  final int skip;
  final int limit;

  const GetPlansParams({
    required this.language,
    this.search,
    this.tag,
    this.skip = 0,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [language, search, tag, skip, limit];

  /// Create a copy with different parameters for pagination
  GetPlansParams copyWith({
    String? language,
    String? search,
    String? tag,
    int? skip,
    int? limit,
  }) {
    return GetPlansParams(
      language: language ?? this.language,
      search: search ?? this.search,
      tag: tag ?? this.tag,
      skip: skip ?? this.skip,
      limit: limit ?? this.limit,
    );
  }
}

/// Get plan detail use case.
class GetPlanDetailUseCase extends UseCase<Plan?, GetPlanDetailParams> {
  final PlansRepository _repository;

  GetPlanDetailUseCase(this._repository);

  @override
  Future<Either<Failure, Plan?>> call(GetPlanDetailParams params) async {
    if (params.planId.isEmpty) {
      return const Left(ValidationFailure('Plan ID cannot be empty'));
    }
    return await _repository.getPlan(params.planId);
  }
}

class GetPlanDetailParams extends Equatable {
  final String planId;

  const GetPlanDetailParams({required this.planId});

  @override
  List<Object?> get props => [planId];
}

/// Enroll in plan use case.
class EnrollInPlanUseCase extends UseCase<PlanProgress, EnrollInPlanParams> {
  final PlansRepository _repository;

  EnrollInPlanUseCase(this._repository);

  @override
  Future<Either<Failure, PlanProgress>> call(EnrollInPlanParams params) async {
    if (params.planId.isEmpty) {
      return const Left(ValidationFailure('Plan ID cannot be empty'));
    }
    return await _repository.enrollInPlan(params.planId);
  }
}

class EnrollInPlanParams extends Equatable {
  final String planId;

  const EnrollInPlanParams({required this.planId});

  @override
  List<Object?> get props => [planId];
}

/// Update plan progress use case.
class UpdateProgressUseCase extends UseCase<PlanProgress, UpdateProgressParams> {
  final PlansRepository _repository;

  UpdateProgressUseCase(this._repository);

  @override
  Future<Either<Failure, PlanProgress>> call(UpdateProgressParams params) async {
    if (params.planId.isEmpty) {
      return const Left(ValidationFailure('Plan ID cannot be empty'));
    }
    if (params.dayNumber < 1) {
      return const Left(ValidationFailure('Day number must be positive'));
    }
    return await _repository.updateProgress(
      params.planId,
      params.dayNumber,
      params.taskId,
    );
  }
}

class UpdateProgressParams extends Equatable {
  final String planId;
  final int dayNumber;
  final String? taskId;

  const UpdateProgressParams({
    required this.planId,
    required this.dayNumber,
    this.taskId,
  });

  @override
  List<Object?> get props => [planId, dayNumber, taskId];
}

/// Search plans use case.
class SearchPlansUseCase extends UseCase<List<Plan>, SearchPlansParams> {
  final PlansRepository _repository;

  SearchPlansUseCase(this._repository);

  @override
  Future<Either<Failure, List<Plan>>> call(SearchPlansParams params) async {
    if (params.query.isEmpty) {
      return const Left(ValidationFailure('Search query cannot be empty'));
    }
    return await _repository.searchPlans(params.query);
  }
}

class SearchPlansParams extends Equatable {
  final String query;

  const SearchPlansParams({required this.query});

  @override
  List<Object?> get props => [query];
}
