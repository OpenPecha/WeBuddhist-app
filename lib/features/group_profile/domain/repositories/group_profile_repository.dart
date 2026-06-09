import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';

abstract class GroupProfileRepositoryInterface {
  Future<Either<Failure, GroupProfile>> getGroupProfile(
    String groupId, {
    required String language,
  });

  Future<Either<Failure, void>> followGroup(String groupId);

  Future<Either<Failure, void>> unfollowGroup(String groupId);
}
