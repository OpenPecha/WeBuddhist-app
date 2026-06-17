import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/connect/data/datasource/connect_remote_datasource.dart';
import 'package:flutter_pecha/features/connect/domain/repositories/connect_repository.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';

class ConnectRepository implements ConnectRepositoryInterface {
  ConnectRepository({required this.remote});

  final ConnectRemoteDatasource remote;

  @override
  Future<Either<Failure, List<GroupProfile>>> getDiscoverGroups({
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final models = await remote.fetchDiscoverGroups(
        language: language,
        skip: skip,
        limit: limit,
      );
      return Right(models.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load discover groups: $e'));
    }
  }

  @override
  Future<Either<Failure, List<GroupProfile>>> getJoinedGroups({
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final models = await remote.fetchJoinedGroups(
        language: language,
        skip: skip,
        limit: limit,
      );
      return Right(models.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load joined groups: $e'));
    }
  }
}
