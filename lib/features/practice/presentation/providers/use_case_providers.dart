import 'package:flutter_pecha/features/practice/domain/usecases/complete_practice_usecase.dart';
import 'package:flutter_pecha/features/practice/domain/usecases/get_practice_progress_usecase.dart';
import 'package:flutter_pecha/features/practice/domain/usecases/get_routines_usecase.dart';
import 'package:flutter_pecha/features/practice/domain/usecases/start_practice_usecase.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Local storage use case providers ───
// These use cases operate on the device-local Hive-backed routine store.

/// Provider for [GetRoutinesUseCase].
final getRoutinesUseCaseProvider = Provider<GetRoutinesUseCase>((ref) {
  return GetRoutinesUseCase(ref.watch(practiceRepositoryProvider));
});

/// Provider for [StartPracticeUseCase].
final startPracticeUseCaseProvider = Provider<StartPracticeUseCase>((ref) {
  return StartPracticeUseCase(ref.watch(practiceRepositoryProvider));
});

/// Provider for [CompletePracticeUseCase].
final completePracticeUseCaseProvider = Provider<CompletePracticeUseCase>((ref) {
  return CompletePracticeUseCase(ref.watch(practiceRepositoryProvider));
});

/// Provider for [GetPracticeProgressUseCase].
final getPracticeProgressUseCaseProvider =
    Provider<GetPracticeProgressUseCase>((ref) {
  return GetPracticeProgressUseCase(ref.watch(practiceRepositoryProvider));
});
