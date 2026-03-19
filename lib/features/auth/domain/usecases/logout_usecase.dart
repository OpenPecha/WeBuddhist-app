import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:fpdart/fpdart.dart';

/// Logout use case.
class LogoutUseCase extends UseCase<void, NoParams> {
  final void Function() _logoutFn;

  LogoutUseCase(this._logoutFn);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      _logoutFn();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('Logout failed: $e'));
    }
  }
}
