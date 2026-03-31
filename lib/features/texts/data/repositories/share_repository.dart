import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/texts/data/datasource/share_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/domain/repositories/share_repository.dart';

class ShareRepository implements ShareRepositoryInterface {
  final ShareRemoteDatasource remoteDatasource;

  ShareRepository({required this.remoteDatasource});

  @override
  Future<Either<Failure, String>> getShareUrl({
    required String textId,
    required String segmentId,
    required String language,
  }) async {
    if (textId.isEmpty || segmentId.isEmpty || language.isEmpty) {
      return const Left(ValidationFailure('All parameters must be non-empty'));
    }

    try {
      final shortUrl = await remoteDatasource.getShareUrl(
        textId: textId,
        segmentId: segmentId,
        language: language,
      );

      if (shortUrl.isEmpty) {
        return const Left(ServerFailure('Server returned empty share URL'));
      }

      return Right(shortUrl);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to generate share URL'));
    }
  }
}
