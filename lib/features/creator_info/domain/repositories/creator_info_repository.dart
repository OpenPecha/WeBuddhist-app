import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/creator_info/domain/entities/creator_info.dart';
import 'package:flutter_pecha/shared/domain/base_classes/repository.dart';

/// Creator info repository interface.
abstract class CreatorInfoRepository extends Repository {
  /// Get creator information.
  Future<Either<Failure, CreatorInfo>> getCreatorInfo();
}
