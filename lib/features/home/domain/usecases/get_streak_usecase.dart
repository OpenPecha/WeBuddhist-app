import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

class GetStreakUseCase extends UseCase<int, NoParams> {
  final Future<Either<Failure, int>> Function() _getStreak;

  GetStreakUseCase(this._getStreak);

  @override
  Future<Either<Failure, int>> call(NoParams params) async {
    return _getStreak();
  }
}
