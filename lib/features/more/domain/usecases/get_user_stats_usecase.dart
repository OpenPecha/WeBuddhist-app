import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/more/domain/entities/user_stats.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

class GetUserStatsUseCase extends UseCase<UserStats, NoParams> {
  final Future<Either<Failure, UserStats>> Function() _getUserStats;

  GetUserStatsUseCase(this._getUserStats);

  @override
  Future<Either<Failure, UserStats>> call(NoParams params) async {
    return _getUserStats();
  }
}
