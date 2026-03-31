import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';

/// Base class for all use cases.
///
/// Use cases encapsulate business logic and should be independent of
/// the presentation layer. They return Either&lt;Failure, T&gt; for error handling.
///
/// Example usage:
/// ```dart
/// class LoginUseCase extends UseCase<User, LoginParams> {
///   final AuthRepository _repository;
///
///   LoginUseCase(this._repository);
///
///   @override
///   Future<Either<Failure, User>> call(LoginParams params) async {
///     return await _repository.login(params.email, params.password);
///   }
/// }
/// ```
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Use case with no parameters.
class NoParams {
  const NoParams();
}
