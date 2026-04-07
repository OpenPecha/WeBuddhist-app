import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/practice/data/datasource/routine_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/repositories/routine_repository_impl.dart';
import 'package:flutter_pecha/features/practice/domain/repositories/routine_repository.dart';
import 'package:flutter_pecha/features/practice/domain/usecases/routine_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========== Repository Provider ==========

/// Provider for RoutineRepository implementation (domain interface).
final routineDomainRepositoryProvider = Provider<RoutineRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final datasource = RoutineRemoteDatasource(dio: dio);
  return RoutineRepositoryImpl(remoteDatasource: datasource);
});

// ========== Use Case Providers ==========

/// Provider for GetUserRoutineUseCase.
final getUserRoutineUseCaseProvider = Provider<GetUserRoutineUseCase>((ref) {
  final repository = ref.watch(routineDomainRepositoryProvider);
  return GetUserRoutineUseCase(repository);
});

/// Provider for CreateRoutineUseCase.
final createRoutineUseCaseProvider = Provider<CreateRoutineUseCase>((ref) {
  final repository = ref.watch(routineDomainRepositoryProvider);
  return CreateRoutineUseCase(repository);
});

/// Provider for CreateTimeBlockUseCase.
final createTimeBlockUseCaseProvider = Provider<CreateTimeBlockUseCase>((ref) {
  final repository = ref.watch(routineDomainRepositoryProvider);
  return CreateTimeBlockUseCase(repository);
});

/// Provider for UpdateTimeBlockUseCase.
final updateTimeBlockUseCaseProvider = Provider<UpdateTimeBlockUseCase>((ref) {
  final repository = ref.watch(routineDomainRepositoryProvider);
  return UpdateTimeBlockUseCase(repository);
});

/// Provider for DeleteTimeBlockUseCase.
final deleteTimeBlockUseCaseProvider = Provider<DeleteTimeBlockUseCase>((ref) {
  final repository = ref.watch(routineDomainRepositoryProvider);
  return DeleteTimeBlockUseCase(repository);
});
