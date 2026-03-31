import 'package:flutter_pecha/features/practice/data/datasource/routine_local_storage.dart';
import 'package:flutter_pecha/features/practice/data/repositories/practice_repository_impl.dart';
import 'package:flutter_pecha/features/practice/data/services/routine_notification_service.dart';
import 'package:flutter_pecha/features/practice/domain/repositories/practice_repository.dart';
import 'package:flutter_pecha/features/practice/domain/usecases/complete_practice_usecase.dart';
import 'package:flutter_pecha/features/practice/domain/usecases/get_practice_progress_usecase.dart';
import 'package:flutter_pecha/features/practice/domain/usecases/get_routines_usecase.dart';
import 'package:flutter_pecha/features/practice/domain/usecases/start_practice_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========== Data Layer Providers ==========

/// Provider for RoutineLocalStorage.
///
/// Must be overridden in ProviderScope with an initialized instance from main.dart.
final routineLocalStorageProvider = Provider<RoutineLocalStorage>((ref) {
  throw UnimplementedError(
    'routineLocalStorageProvider must be overridden in ProviderScope',
  );
});

/// Provider for RoutineNotificationService (singleton).
final routineNotificationServiceProvider = Provider<RoutineNotificationService>((ref) {
  return RoutineNotificationService();
});

/// Provider for Practice Repository.
final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  final localStorage = ref.watch(routineLocalStorageProvider);
  final notificationService = ref.watch(routineNotificationServiceProvider);

  return PracticeRepositoryImpl(
    localStorage: localStorage,
    notificationService: notificationService,
  );
});

// ========== Use Case Providers ==========

/// Provider for GetRoutinesUseCase.
final getRoutinesUseCaseProvider = Provider<GetRoutinesUseCase>((ref) {
  final repository = ref.watch(practiceRepositoryProvider);
  return GetRoutinesUseCase(repository);
});

/// Provider for StartPracticeUseCase.
final startPracticeUseCaseProvider = Provider<StartPracticeUseCase>((ref) {
  final repository = ref.watch(practiceRepositoryProvider);
  return StartPracticeUseCase(repository);
});

/// Provider for CompletePracticeUseCase.
final completePracticeUseCaseProvider = Provider<CompletePracticeUseCase>((ref) {
  final repository = ref.watch(practiceRepositoryProvider);
  return CompletePracticeUseCase(repository);
});

/// Provider for GetPracticeProgressUseCase.
final getPracticeProgressUseCaseProvider = Provider<GetPracticeProgressUseCase>((ref) {
  final repository = ref.watch(practiceRepositoryProvider);
  return GetPracticeProgressUseCase(repository);
});
