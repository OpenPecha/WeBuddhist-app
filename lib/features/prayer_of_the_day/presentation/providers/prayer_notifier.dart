import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/domain/usecases/get_today_prayer_usecase.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/presentation/providers/prayer_providers.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/presentation/state/prayer_state.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State notifier for prayer feature.
class PrayerNotifier extends StateNotifier<PrayerState> {
  final GetTodayPrayerUseCase _getTodayPrayerUseCase;
  final MarkPrayerCompletedUseCase _markPrayerCompletedUseCase;

  PrayerNotifier(
    this._getTodayPrayerUseCase,
    this._markPrayerCompletedUseCase,
  ) : super(const PrayerInitial());

  /// Load today's prayer.
  Future<void> loadTodayPrayer() async {
    state = const PrayerLoading();

    final result = await _getTodayPrayerUseCase(NoParams());

    result.fold(
      (failure) {
        state = PrayerError(_getErrorMessage(failure));
      },
      (prayer) {
        state = PrayerLoaded(prayer);
      },
    );
  }

  /// Mark prayer as completed.
  Future<void> markAsCompleted(String prayerId) async {
    final result = await _markPrayerCompletedUseCase(
      MarkCompletedParams(prayerId: prayerId),
    );

    result.fold(
      (failure) {
        // Could emit error state or show snackbar
        state = PrayerError(_getErrorMessage(failure));
      },
      (_) {
        // Refresh prayer data to show completion status
        loadTodayPrayer();
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    switch (failure) {
      case NetworkFailure():
        return 'Network error. Please check your connection.';
      case CacheFailure():
        return 'Failed to load prayer data.';
      case ValidationFailure():
        return failure.message;
      default:
        return 'An unexpected error occurred.';
    }
  }
}

/// Provider for PrayerNotifier.
final prayerNotifierProvider =
    StateNotifierProvider<PrayerNotifier, PrayerState>((ref) {
  final getTodayPrayerUseCase = ref.watch(getTodayPrayerUseCaseProvider);
  final markPrayerCompletedUseCase = ref.watch(markPrayerCompletedUseCaseProvider);

  return PrayerNotifier(
    getTodayPrayerUseCase,
    markPrayerCompletedUseCase,
  );
});
