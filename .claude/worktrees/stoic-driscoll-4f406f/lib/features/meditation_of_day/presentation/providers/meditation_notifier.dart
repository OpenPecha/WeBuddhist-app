import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/meditation_of_day/domain/usecases/get_today_meditation_usecase.dart';
import 'package:flutter_pecha/features/meditation_of_day/presentation/providers/meditation_providers.dart';
import 'package:flutter_pecha/features/meditation_of_day/presentation/state/meditation_state.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State notifier for meditation feature.
class MeditationNotifier extends StateNotifier<MeditationState> {
  final GetTodayMeditationUseCase _getTodayMeditationUseCase;
  final MarkMeditationCompletedUseCase _markMeditationCompletedUseCase;

  MeditationNotifier(
    this._getTodayMeditationUseCase,
    this._markMeditationCompletedUseCase,
  ) : super(const MeditationInitial());

  /// Load today's meditation.
  Future<void> loadTodayMeditation() async {
    state = const MeditationLoading();

    final result = await _getTodayMeditationUseCase(NoParams());

    result.fold(
      (failure) {
        state = MeditationError(_getErrorMessage(failure));
      },
      (meditation) {
        state = MeditationLoaded(meditation);
      },
    );
  }

  /// Mark meditation as completed.
  Future<void> markAsCompleted(String meditationId) async {
    final result = await _markMeditationCompletedUseCase(
      MarkCompletedParams(meditationId: meditationId),
    );

    result.fold(
      (failure) {
        // Could emit error state or show snackbar
        state = MeditationError(_getErrorMessage(failure));
      },
      (_) {
        // Refresh meditation data to show completion status
        loadTodayMeditation();
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    switch (failure) {
      case NetworkFailure():
        return 'Network error. Please check your connection.';
      case CacheFailure():
        return 'Failed to load meditation data.';
      case ValidationFailure():
        return failure.message;
      default:
        return 'An unexpected error occurred.';
    }
  }
}

/// Provider for MeditationNotifier.
final meditationNotifierProvider =
    StateNotifierProvider<MeditationNotifier, MeditationState>((ref) {
  final getTodayMeditationUseCase = ref.watch(getTodayMeditationUseCaseProvider);
  final markMeditationCompletedUseCase = ref.watch(markMeditationCompletedUseCaseProvider);

  return MeditationNotifier(
    getTodayMeditationUseCase,
    markMeditationCompletedUseCase,
  );
});
