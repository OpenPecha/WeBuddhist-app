import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

class GetGroupProfileUseCase
    extends UseCase<GroupProfile, GetGroupProfileParams> {
  final Future<Either<Failure, GroupProfile>> Function(
    String groupId, {
    required String language,
  })
  _getGroupProfile;

  GetGroupProfileUseCase(this._getGroupProfile);

  @override
  Future<Either<Failure, GroupProfile>> call(
    GetGroupProfileParams params,
  ) async {
    return _getGroupProfile(params.groupId, language: params.language);
  }
}

class GetGroupProfileParams {
  final String groupId;
  final String language;

  const GetGroupProfileParams({required this.groupId, required this.language});
}
