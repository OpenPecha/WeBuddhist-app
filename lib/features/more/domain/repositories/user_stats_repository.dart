import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/more/domain/entities/user_stats.dart';
import 'package:flutter_pecha/shared/domain/base_classes/repository.dart';

abstract class UserStatsRepositoryInterface extends Repository {
  Future<Either<Failure, UserStats>> getUserStats();
}
