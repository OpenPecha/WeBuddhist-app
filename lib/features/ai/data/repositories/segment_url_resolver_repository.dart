import '../datasource/segment_url_resolver_datasource.dart';

/// Repository for resolving segment URLs
class SegmentUrlResolverRepository {
  final SegmentUrlResolverDatasource datasource;

  SegmentUrlResolverRepository({required this.datasource});

  /// Resolves a pecha segment ID to text_id and segment_id
  /// 
  /// Returns a map with 'textId' and 'segmentId' keys
  /// Throws exceptions if the request fails
  Future<Map<String, String>> resolveSegmentUrl(String pechaSegmentId) async {
    return await datasource.resolveSegmentUrl(pechaSegmentId);
  }
}
