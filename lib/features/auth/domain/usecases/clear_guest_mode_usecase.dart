import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:fpdart/fpdart.dart';

/// Clear guest mode use case.
///
/// Clears guest mode for the user.
class ClearGuestModeUseCase extends UseCase<void, NoParams> {
  final AuthRepository _repository;

  ClearGuestModeUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await _repository.clearGuestMode();
  }
}
