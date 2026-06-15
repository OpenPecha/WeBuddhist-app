import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/data/datasource/routine_info_remote_datasource.dart';
import 'package:flutter_pecha/features/home/domain/entities/routine_info.dart';
import 'package:flutter_pecha/features/home/domain/repositories/home_repository.dart';

class RoutineInfoRepository implements RoutineInfoRepositoryInterface {
  final RoutineInfoRemoteDatasource remote;

  RoutineInfoRepository({required this.remote});

  @override
  Future<Either<Failure, RoutineInfo>> getRoutineInfo() async {
    try {
      final model = await remote.fetchRoutineInfo();
      return Right(model.toEntity());
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
      return Left(UnknownFailure('Failed to get routine info: $e'));
    }
  }
}
