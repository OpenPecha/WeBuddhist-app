import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';

/// Domain interface for share repository.
abstract class ShareRepositoryInterface {
  Future<Either<Failure, String>> getShareUrl({
    required String textId,
    required String segmentId,
    required String language,
  });
}
