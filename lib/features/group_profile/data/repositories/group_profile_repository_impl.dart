import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_profile_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';

class GroupProfileRepositoryImpl implements GroupProfileRepositoryInterface {
  final GroupProfileRemoteDatasource remote;

  GroupProfileRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, GroupProfile>> getGroupProfile(
    String groupId, {
    required String language,
  }) async {
    try {
      final model = await remote.fetchGroupProfile(
        groupId,
        language: language,
      );
      return Right(model.toEntity());
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
      return Left(UnknownFailure('Failed to load group profile: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkFollowStatus(String groupId) async {
    try {
      final isFollowing = await remote.checkFollowStatus(groupId);
      return Right(isFollowing);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to check follow status: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> followGroup(String groupId) async {
    try {
      await remote.followGroup(groupId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to follow group: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> unfollowGroup(String groupId) async {
    try {
      await remote.unfollowGroup(groupId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to unfollow group: $e'));
    }
  }
}
