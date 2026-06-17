import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';

abstract class ConnectRepositoryInterface {
  Future<Either<Failure, List<GroupProfile>>> getDiscoverGroups({
    required String language,
    int skip,
    int limit,
  });

  Future<Either<Failure, List<GroupProfile>>> getJoinedGroups({
    required String language,
    int skip,
    int limit,
  });
}
