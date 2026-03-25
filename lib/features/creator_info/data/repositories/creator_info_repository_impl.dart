import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/creator_info/data/datasource/creator_info_local_datasource.dart';
import 'package:flutter_pecha/features/creator_info/domain/entities/creator_info.dart';
import 'package:flutter_pecha/features/creator_info/domain/repositories/creator_info_repository.dart';

/// Creator info repository implementation.
class CreatorInfoRepositoryImpl implements CreatorInfoRepository {
  final CreatorInfoLocalDataSource _localDataSource;

  CreatorInfoRepositoryImpl({
    required CreatorInfoLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<Either<Failure, CreatorInfo>> getCreatorInfo() async {
    try {
      final model = await _localDataSource.getCreatorInfo();
      if (model == null) {
        return Left(CacheFailure('Creator info not found'));
      }
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to load creator info: $e'));
    }
  }
}
