import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/data/datasource/tasks_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_tasks_model.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/tasks_repository.dart';

class TasksRepository implements TasksRepositoryInterface {
  final TasksRemoteDatasource tasksRemoteDatasource;

  TasksRepository({required this.tasksRemoteDatasource});

  @override
  Future<Either<Failure, List<PlanTasksModel>>> getTasksByPlanItemId(String planItemId) async {
    try {
      final result = await tasksRemoteDatasource.getTasksByPlanItemId(planItemId);
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to load tasks'));
    }
  }

  @override
  Future<Either<Failure, PlanTasksModel>> getTaskById(String id) async {
    try {
      final result = await tasksRemoteDatasource.getTaskById(id);
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to load task'));
    }
  }
}
