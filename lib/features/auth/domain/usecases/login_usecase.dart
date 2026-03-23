import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:fpdart/fpdart.dart';

/// Login use case.
///
/// Handles both Google and Apple login based on the connection parameter.
class LoginUseCase extends UseCase<Credentials?, LoginParams> {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  @override
  Future<Either<Failure, Credentials?>> call(LoginParams params) async {
    try {
      Credentials? credentials;

      switch (params.connection) {
        case 'google':
          credentials = await _repository.loginWithGoogle();
          break;
        case 'apple':
          credentials = await _repository.loginWithApple();
          break;
        default:
          return Left(AuthenticationFailure('Unsupported login method: ${params.connection}'));
      }

      return Right(credentials);
    } catch (e) {
      return Left(AuthenticationFailure('Login failed: $e'));
    }
  }
}

/// Parameters for login use case.
class LoginParams {
  final String? connection;

  const LoginParams({this.connection});
}
