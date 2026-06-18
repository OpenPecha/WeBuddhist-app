import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:fpdart/fpdart.dart';

/// Has valid credentials use case.
///
/// Checks if the user has valid credentials.
class HasValidCredentialsUseCase extends UseCase<bool, NoParams> {
  final AuthRepository _repository;

  HasValidCredentialsUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await _repository.hasValidCredentials();
  }
}
