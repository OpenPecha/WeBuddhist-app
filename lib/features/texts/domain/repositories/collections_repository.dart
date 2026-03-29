import 'package:flutter_pecha/features/texts/data/models/collections/collections_response.dart';

/// Domain interface for collections repository.
abstract class CollectionsRepositoryInterface {
  Future<CollectionsResponse> getCollections({
    String? parentId,
    String? language,
    bool forceRefresh = false,
  });
}
