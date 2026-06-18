import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/creator_info/domain/usecases/get_creator_info_usecase.dart';
import 'package:flutter_pecha/features/creator_info/presentation/providers/creator_info_providers.dart';
import 'package:flutter_pecha/features/creator_info/presentation/state/creator_info_state.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State notifier for creator info feature.
class CreatorInfoNotifier extends StateNotifier<CreatorInfoState> {
  final GetCreatorInfoUseCase _getCreatorInfoUseCase;

  CreatorInfoNotifier(this._getCreatorInfoUseCase) : super(const CreatorInfoInitial());

  /// Load creator info.
  Future<void> loadCreatorInfo() async {
    state = const CreatorInfoLoading();

    final result = await _getCreatorInfoUseCase(NoParams());

    result.fold(
      (failure) {
        state = CreatorInfoError(_getErrorMessage(failure));
      },
      (creatorInfo) {
        state = CreatorInfoLoaded(creatorInfo);
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    switch (failure) {
      case NetworkFailure():
        return 'Network error. Please check your connection.';
      case CacheFailure():
        return 'Failed to load creator info.';
      default:
        return 'An unexpected error occurred.';
    }
  }
}

/// Provider for CreatorInfoNotifier.
final creatorInfoNotifierProvider =
    StateNotifierProvider<CreatorInfoNotifier, CreatorInfoState>((ref) {
  final getCreatorInfoUseCase = ref.watch(getCreatorInfoUseCaseProvider);

  return CreatorInfoNotifier(getCreatorInfoUseCase);
});
