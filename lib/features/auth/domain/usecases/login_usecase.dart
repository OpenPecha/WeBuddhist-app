import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/entities/auth_credentials.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:fpdart/fpdart.dart';

/// Login use case.
///
/// Handles both Google and Apple login based on the connection parameter.
class LoginUseCase extends UseCase<AuthCredentials, LoginParams> {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  @override
  Future<Either<Failure, AuthCredentials>> call(LoginParams params) async {
    switch (params.connection) {
      case 'google':
        return await _repository.loginWithGoogle();
      case 'apple':
        return await _repository.loginWithApple();
      default:
        return const Left(AuthenticationFailure('Unsupported login method'));
    }
  }
}

/// Parameters for login use case.
class LoginParams {
  final String? connection;

  const LoginParams({this.connection});
}
