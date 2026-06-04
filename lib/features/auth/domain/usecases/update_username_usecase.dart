import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/entities/username_update_result.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:fpdart/fpdart.dart';

/// PATCH /users/username — checks availability and saves if not taken.
class UpdateUsernameUseCase extends UseCase<UsernameUpdateResult, String> {
  final AuthRepository _repository;

  UpdateUsernameUseCase(this._repository);

  @override
  Future<Either<Failure, UsernameUpdateResult>> call(String username) {
    return _repository.updateUsername(username);
  }
}
