import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/reader/domain/entities/text_content.dart';
import 'package:flutter_pecha/features/reader/domain/repositories/reader_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Load initial text content use case.
class LoadInitialTextUseCase extends UseCase<TextContent, LoadTextParams> {
  final ReaderRepository _repository;

  LoadInitialTextUseCase(this._repository);

  @override
  Future<Either<Failure, TextContent>> call(LoadTextParams params) async {
    if (params.textId.isEmpty) {
      return const Left(ValidationFailure('Text ID cannot be empty'));
    }
    return await _repository.loadInitialText(params.textId);
  }
}

/// Parameters for loading text content.
class LoadTextParams {
  final String textId;

  const LoadTextParams({required this.textId});
}
