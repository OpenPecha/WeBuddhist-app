import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/clear_guest_mode_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/is_guest_mode_usecase.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:fpdart/fpdart.dart';

/// Clear guest mode and onboarding use case.
///
/// Combines clearing guest mode with onboarding reset.
/// This is a complex operation that was previously in AuthNotifier.
class ClearGuestModeAndOnboardingUseCase extends UseCase<void, ClearGuestModeAndOnboardingParams> {
  final ClearGuestModeUseCase _clearGuestModeUseCase;
  final IsGuestModeUseCase _isGuestModeUseCase;

  ClearGuestModeAndOnboardingUseCase(
    this._clearGuestModeUseCase,
    this._isGuestModeUseCase,
  );

  @override
  Future<Either<Failure, void>> call(ClearGuestModeAndOnboardingParams params) async {
    // Clear guest mode
    final clearGuestResult = await _clearGuestModeUseCase(const NoParams());
    return clearGuestResult.fold(
      (failure) {
        return Left(UnknownFailure('Failed to clear guest mode: ${failure.message}'));
      },
      (_) {
        return const Right(null);
      },
    );
  }
}

/// Parameters for clear guest mode and onboarding use case.
class ClearGuestModeAndOnboardingParams {
  final bool wasGuest;

  const ClearGuestModeAndOnboardingParams({required this.wasGuest});
}
