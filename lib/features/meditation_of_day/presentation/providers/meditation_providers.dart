import 'package:flutter_pecha/features/meditation_of_day/data/datasource/meditation_local_datasource.dart';
import 'package:flutter_pecha/features/meditation_of_day/data/repositories/meditation_repository_impl.dart';
import 'package:flutter_pecha/features/meditation_of_day/domain/repositories/meditation_repository.dart';
import 'package:flutter_pecha/features/meditation_of_day/domain/usecases/get_today_meditation_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========== Data Layer Providers ==========

/// Provider for MeditationLocalDataSource.
final meditationLocalDataSourceProvider = Provider<MeditationLocalDataSource>((ref) {
  return MeditationLocalDataSource();
});

/// Provider for Meditation Repository.
final meditationRepositoryProvider = Provider<MeditationRepository>((ref) {
  final localDataSource = ref.watch(meditationLocalDataSourceProvider);
  return MeditationRepositoryImpl(localDataSource: localDataSource);
});

// ========== Use Case Providers ==========

/// Provider for GetTodayMeditationUseCase.
final getTodayMeditationUseCaseProvider = Provider<GetTodayMeditationUseCase>((ref) {
  final repository = ref.watch(meditationRepositoryProvider);
  return GetTodayMeditationUseCase(repository);
});

/// Provider for MarkMeditationCompletedUseCase.
final markMeditationCompletedUseCaseProvider = Provider<MarkMeditationCompletedUseCase>((ref) {
  final repository = ref.watch(meditationRepositoryProvider);
  return MarkMeditationCompletedUseCase(repository);
});
