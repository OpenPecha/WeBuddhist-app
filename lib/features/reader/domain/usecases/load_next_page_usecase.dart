import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/reader/domain/entities/text_content.dart';
import 'package:flutter_pecha/features/reader/domain/repositories/reader_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Load next page of verses use case.
class LoadNextPageUseCase extends UseCase<List<Verse>, LoadNextPageParams> {
  final ReaderRepository _repository;

  LoadNextPageUseCase(this._repository);

  @override
  Future<Either<Failure, List<Verse>>> call(LoadNextPageParams params) async {
    if (params.textId.isEmpty) {
      return const Left(ValidationFailure('Text ID cannot be empty'));
    }
    if (params.pageIndex < 0) {
      return const Left(ValidationFailure('Page index must be non-negative'));
    }
    return await _repository.loadNextPage(params.textId, params.pageIndex);
  }
}

/// Parameters for loading next page.
class LoadNextPageParams {
  final String textId;
  final int pageIndex;

  const LoadNextPageParams({
    required this.textId,
    required this.pageIndex,
  });
}
