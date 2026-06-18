import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/entities/auth_credentials.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:fpdart/fpdart.dart';

/// Get credentials use case.
///
/// Gets the current auth credentials.
class GetCredentialsUseCase extends UseCase<AuthCredentials, NoParams> {
  final AuthRepository _repository;

  GetCredentialsUseCase(this._repository);

  @override
  Future<Either<Failure, AuthCredentials>> call(NoParams params) async {
    return await _repository.getCredentials();
  }
}
