import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/recitation/domain/entities/recitation.dart';
import 'package:flutter_pecha/features/recitation/domain/repositories/recitation_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Get recitations use case.
class GetRecitationsUseCase extends UseCase<List<Recitation>, NoParams> {
  final RecitationRepository _repository;

  GetRecitationsUseCase(this._repository);

  @override
  Future<Either<Failure, List<Recitation>>> call(NoParams params) async {
    return await _repository.getRecitations();
  }
}

/// Search recitations use case.
class SearchRecitationsUseCase extends UseCase<List<Recitation>, SearchRecitationsParams> {
  final RecitationRepository _repository;

  SearchRecitationsUseCase(this._repository);

  @override
  Future<Either<Failure, List<Recitation>>> call(SearchRecitationsParams params) async {
    return await _repository.searchRecitations(params.query);
  }
}

class SearchRecitationsParams {
  final String query;
  const SearchRecitationsParams({required this.query});
}
