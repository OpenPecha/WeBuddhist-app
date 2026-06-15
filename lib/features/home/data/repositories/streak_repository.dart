import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/data/datasource/streak_remote_datasource.dart';
import 'package:flutter_pecha/features/home/domain/repositories/home_repository.dart';

class StreakRepository implements StreakRepositoryInterface {
  final StreakRemoteDatasource remote;

  StreakRepository({required this.remote});

  @override
  Future<Either<Failure, int>> getStreak() async {
    try {
      final streak = await remote.fetchStreak();
      return Right(streak);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to get streak: $e'));
    }
  }
}
