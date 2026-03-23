import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:fpdart/fpdart.dart';

/// Refresh ID token use case.
///
/// Refreshes the ID token.
class RefreshIdTokenUseCase extends UseCase<String?, NoParams> {
  final AuthRepository _repository;

  RefreshIdTokenUseCase(this._repository);

  @override
  Future<Either<Failure, String?>> call(NoParams params) async {
    try {
      final idToken = await _repository.refreshIdToken();
      return Right(idToken);
    } catch (e) {
      return Left(AuthenticationFailure('Failed to refresh ID token: $e'));
    }
  }
}
