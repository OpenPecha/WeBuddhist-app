import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/texts/data/models/collections/collections_response.dart';

/// Domain interface for collections repository.
abstract class CollectionsRepositoryInterface {
  Future<Either<Failure, CollectionsResponse>> getCollections({
    String? parentId,
    String? language,
    bool forceRefresh = false,
  });
}
