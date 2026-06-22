import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:fpdart/fpdart.dart';

/// Force-refresh access token use case.
///
/// Forces a renewal through the credentials manager and returns a fresh
/// access token (reactive 401 path).
class ForceRefreshAccessTokenUseCase extends UseCase<String, NoParams> {
  final AuthRepository _repository;

  ForceRefreshAccessTokenUseCase(this._repository);

  @override
  Future<Either<Failure, String>> call(NoParams params) async {
    return await _repository.forceRefreshAccessToken();
  }
}
