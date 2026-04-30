import 'package:flutter_pecha/features/practice/data/datasource/routine_local_storage.dart';
import 'package:flutter_pecha/features/practice/data/repositories/practice_repository_impl.dart';
import 'package:flutter_pecha/features/notifications/data/services/routine_notification_service.dart';
import 'package:flutter_pecha/features/practice/domain/repositories/practice_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Infrastructure providers ───

/// Provider for [RoutineLocalStorage] (Hive-backed persistent storage).
///
/// **Must be overridden** in the root [ProviderScope] / [ProviderContainer]
/// with an already-initialised instance.
///
/// Override location: `lib/main.dart` → `ProviderContainer(overrides: [...])`
///
/// ```dart
/// final routineStorage = RoutineLocalStorage();
/// await routineStorage.initialize();
/// ProviderContainer(overrides: [
///   routineLocalStorageProvider.overrideWithValue(routineStorage),
/// ]);
/// ```
final routineLocalStorageProvider = Provider<RoutineLocalStorage>((ref) {
  throw UnimplementedError(
    'routineLocalStorageProvider must be overridden before use. '
    'See lib/main.dart for the initialisation pattern.',
  );
});

/// Provider for [RoutineNotificationService] (app-wide singleton).
final routineNotificationServiceProvider =
    Provider<RoutineNotificationService>((ref) {
  return RoutineNotificationService();
});

/// Provider for [PracticeRepository] — the domain interface for local
/// routine storage and session operations.
final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  return PracticeRepositoryImpl(
    localStorage: ref.watch(routineLocalStorageProvider),
    notificationService: ref.watch(routineNotificationServiceProvider),
  );
});
