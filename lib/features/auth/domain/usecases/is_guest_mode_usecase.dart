import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:fpdart/fpdart.dart';

/// Is guest mode use case.
///
/// Checks if the user is in guest mode.
class IsGuestModeUseCase extends UseCase<bool, NoParams> {
  final AuthRepository _repository;

  IsGuestModeUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    try {
      final isGuest = await _repository.isGuestMode();
      return Right(isGuest);
    } catch (e) {
      return Left(UnknownFailure('Failed to check guest mode: $e'));
    }
  }
}
