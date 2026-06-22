import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/more/domain/entities/series_day_completed.dart';
import 'package:flutter_pecha/features/more/domain/entities/user_stats.dart';
import 'package:flutter_pecha/features/more/domain/usecases/get_series_day_completed_usecase.dart';
import 'package:flutter_pecha/shared/domain/base_classes/repository.dart';

abstract class UserStatsRepositoryInterface extends Repository {
  Future<Either<Failure, UserStats>> getUserStats();

  Future<Either<Failure, SeriesDayCompletedPage>> getSeriesDayCompleted(
    GetSeriesDayCompletedParams params,
  );
}
