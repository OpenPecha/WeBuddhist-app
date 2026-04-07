import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_api_models.dart';
import 'package:flutter_pecha/features/practice/domain/repositories/routine_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

class GetUserRoutineUseCase
    extends UseCase<RoutineResponse?, GetUserRoutineParams> {
  final RoutineRepository _repository;

  GetUserRoutineUseCase(this._repository);

  @override
  Future<Either<Failure, RoutineResponse?>> call(GetUserRoutineParams params) {
    return _repository.getUserRoutine(
      skip: params.skip,
      limit: params.limit,
    );
  }
}

class GetUserRoutineParams extends Equatable {
  final int skip;
  final int limit;

  const GetUserRoutineParams({
    this.skip = 0,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [skip, limit];
}

class CreateRoutineUseCase
    extends UseCase<RoutineWithTimeBlocksResponse, CreateRoutineParams> {
  final RoutineRepository _repository;

  CreateRoutineUseCase(this._repository);

  @override
  Future<Either<Failure, RoutineWithTimeBlocksResponse>> call(
    CreateRoutineParams params,
  ) {
    return _repository.createRoutineWithTimeBlock(params.request);
  }
}

class CreateRoutineParams extends Equatable {
  final CreateTimeBlockRequest request;

  const CreateRoutineParams({required this.request});

  @override
  List<Object?> get props => [request];
}

class CreateTimeBlockUseCase
    extends UseCase<TimeBlockDTO, CreateTimeBlockParams> {
  final RoutineRepository _repository;

  CreateTimeBlockUseCase(this._repository);

  @override
  Future<Either<Failure, TimeBlockDTO>> call(CreateTimeBlockParams params) {
    return _repository.createTimeBlock(
      params.routineId,
      params.request,
    );
  }
}

class CreateTimeBlockParams extends Equatable {
  final String routineId;
  final CreateTimeBlockRequest request;

  const CreateTimeBlockParams({
    required this.routineId,
    required this.request,
  });

  @override
  List<Object?> get props => [routineId, request];
}

class UpdateTimeBlockUseCase
    extends UseCase<TimeBlockDTO, UpdateTimeBlockParams> {
  final RoutineRepository _repository;

  UpdateTimeBlockUseCase(this._repository);

  @override
  Future<Either<Failure, TimeBlockDTO>> call(UpdateTimeBlockParams params) {
    return _repository.updateTimeBlock(
      params.routineId,
      params.timeBlockId,
      params.request,
    );
  }
}

class UpdateTimeBlockParams extends Equatable {
  final String routineId;
  final String timeBlockId;
  final UpdateTimeBlockRequest request;

  const UpdateTimeBlockParams({
    required this.routineId,
    required this.timeBlockId,
    required this.request,
  });

  @override
  List<Object?> get props => [routineId, timeBlockId, request];
}

class DeleteTimeBlockUseCase extends UseCase<void, DeleteTimeBlockParams> {
  final RoutineRepository _repository;

  DeleteTimeBlockUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(DeleteTimeBlockParams params) {
    return _repository.deleteTimeBlock(
      params.routineId,
      params.timeBlockId,
    );
  }
}

class DeleteTimeBlockParams extends Equatable {
  final String routineId;
  final String timeBlockId;

  const DeleteTimeBlockParams({
    required this.routineId,
    required this.timeBlockId,
  });

  @override
  List<Object?> get props => [routineId, timeBlockId];
}
