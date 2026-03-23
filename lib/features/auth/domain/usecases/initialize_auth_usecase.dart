import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:fpdart/fpdart.dart';

/// Initialize auth use case.
///
/// Initializes the auth system (loads config, setup provider).
class InitializeAuthUseCase extends UseCase<void, NoParams> {
  final AuthRepository _repository;

  InitializeAuthUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      await _repository.initialize();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('Failed to initialize auth: $e'));
    }
  }
}
