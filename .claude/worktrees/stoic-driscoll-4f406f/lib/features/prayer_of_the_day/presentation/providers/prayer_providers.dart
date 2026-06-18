import 'package:flutter_pecha/features/prayer_of_the_day/data/datasource/prayer_local_datasource.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/data/repositories/prayer_repository_impl.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/data/services/prayer_audio_handler.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/domain/repositories/prayer_repository.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/domain/usecases/get_today_prayer_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========== Data Layer Providers ==========

/// Provider for PrayerLocalDataSource.
final prayerLocalDataSourceProvider = Provider<PrayerLocalDataSource>((ref) {
  return PrayerLocalDataSource();
});

/// Provider for PrayerAudioHandler.
final prayerAudioHandlerProvider = Provider<PrayerAudioHandler>((ref) {
  return PrayerAudioHandler();
});

/// Provider for Prayer Repository.
final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  final localDataSource = ref.watch(prayerLocalDataSourceProvider);
  return PrayerRepositoryImpl(localDataSource: localDataSource);
});

// ========== Use Case Providers ==========

/// Provider for GetTodayPrayerUseCase.
final getTodayPrayerUseCaseProvider = Provider<GetTodayPrayerUseCase>((ref) {
  final repository = ref.watch(prayerRepositoryProvider);
  return GetTodayPrayerUseCase(repository);
});

/// Provider for MarkPrayerCompletedUseCase.
final markPrayerCompletedUseCaseProvider = Provider<MarkPrayerCompletedUseCase>((ref) {
  final repository = ref.watch(prayerRepositoryProvider);
  return MarkPrayerCompletedUseCase(repository);
});
