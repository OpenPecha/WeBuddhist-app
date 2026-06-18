import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/texts/domain/entities/text.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:flutter_pecha/features/texts/domain/repositories/texts_repository.dart';

/// Get texts use case.
class GetTextsUseCase extends UseCase<List<TextEntity>, NoParams> {
  final TextsRepository _repository;

  GetTextsUseCase(this._repository);

  @override
  Future<Either<Failure, List<TextEntity>>> call(NoParams params) async {
    return await _repository.getTexts();
  }
}

/// Get text detail use case.
class GetTextDetailUseCase extends UseCase<TextEntity?, GetTextDetailParams> {
  final TextsRepository _repository;

  GetTextDetailUseCase(this._repository);

  @override
  Future<Either<Failure, TextEntity?>> call(GetTextDetailParams params) async {
    if (params.textId.isEmpty) {
      return const Left(ValidationFailure('Text ID cannot be empty'));
    }
    return await _repository.getText(params.textId);
  }
}

class GetTextDetailParams {
  final String textId;
  const GetTextDetailParams({required this.textId});
}

/// Search texts use case.
class SearchTextsUseCase extends UseCase<List<TextEntity>, SearchTextsParams> {
  final TextsRepository _repository;

  SearchTextsUseCase(this._repository);

  @override
  Future<Either<Failure, List<TextEntity>>> call(SearchTextsParams params) async {
    if (params.query.trim().isEmpty) {
      return const Left(ValidationFailure('Search query cannot be empty'));
    }
    return await _repository.searchTexts(params.query);
  }
}

class SearchTextsParams {
  final String query;
  const SearchTextsParams({required this.query});
}
