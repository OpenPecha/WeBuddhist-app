import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:fpdart/fpdart.dart';

/// Continue as guest use case.
///
/// Enables guest mode for the user.
class ContinueAsGuestUseCase extends UseCase<void, NoParams> {
  final AuthRepository _repository;

  ContinueAsGuestUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      await _repository.continueAsGuest();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('Failed to continue as guest: $e'));
    }
  }
}
