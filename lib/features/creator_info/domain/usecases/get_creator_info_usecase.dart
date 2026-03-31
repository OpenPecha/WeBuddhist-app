import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/creator_info/domain/entities/creator_info.dart';
import 'package:flutter_pecha/features/creator_info/domain/repositories/creator_info_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Get creator info use case.
class GetCreatorInfoUseCase extends UseCase<CreatorInfo, NoParams> {
  final CreatorInfoRepository _repository;

  GetCreatorInfoUseCase(this._repository);

  @override
  Future<Either<Failure, CreatorInfo>> call(NoParams params) async {
    return await _repository.getCreatorInfo();
  }
}
