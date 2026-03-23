import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:fpdart/fpdart.dart';

/// Get credentials use case.
///
/// Gets the current auth credentials.
class GetCredentialsUseCase extends UseCase<Credentials?, NoParams> {
  final AuthRepository _repository;

  GetCredentialsUseCase(this._repository);

  @override
  Future<Either<Failure, Credentials?>> call(NoParams params) async {
    try {
      final credentials = await _repository.getCredentials();
      return Right(credentials);
    } catch (e) {
      return Left(AuthenticationFailure('Failed to get credentials: $e'));
    }
  }
}
