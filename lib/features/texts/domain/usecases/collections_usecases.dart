import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/texts/data/models/collections/collections_response.dart';
import 'package:flutter_pecha/features/texts/domain/repositories/collections_repository.dart';

/// Use case for getting collections.
class GetCollectionsUseCase {
  final CollectionsRepositoryInterface _repository;

  GetCollectionsUseCase(this._repository);

  Future<CollectionsResponse> call(CollectionsParams params) async {
    return await _repository.getCollections(
      parentId: params.parentId,
      language: params.language,
      forceRefresh: params.forceRefresh,
    );
  }
}

class CollectionsParams extends Equatable {
  final String? parentId;
  final String? language;
  final bool forceRefresh;

  const CollectionsParams({
    this.parentId,
    this.language,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [parentId, language, forceRefresh];
}
