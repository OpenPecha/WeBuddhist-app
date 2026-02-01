import '../datasource/tags_remote_datasource.dart';

class TagsRepository {
  final TagsRemoteDatasource tagsRemoteDatasource;

  TagsRepository({required this.tagsRemoteDatasource});

  /// Get unique tags for plans
  Future<List<String>> getTags({required String language}) async {
    try {
      return await tagsRemoteDatasource.fetchTags(language: language);
    } catch (e) {
      throw Exception('Failed to load tags: $e');
    }
  }
}
