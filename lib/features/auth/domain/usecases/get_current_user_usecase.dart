import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:fpdart/fpdart.dart';

/// Get current authenticated user.
class GetCurrentUserUseCase extends UseCase<User?, NoParams> {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  @override
  Future<Either<Failure, User?>> call(NoParams params) async {
    try {
      final user = await _repository.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(UnknownFailure('Failed to get current user: $e'));
    }
  }
}
