import '../datasource/author_remote_datasource.dart';
import '../../models/author/author_model.dart';
import '../../models/plans_model.dart';

class AuthorRepository {
  final AuthorRemoteDatasource authorRemoteDatasource;

  AuthorRepository({required this.authorRemoteDatasource});

  Future<AuthorModel> getAuthorById(String id) async {
    try {
      return await authorRemoteDatasource.getAuthorById(id);
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  Future<List<PlansModel>> getPlansByAuthorId(String authorId) async {
    try {
      return await authorRemoteDatasource.getPlansByAuthorId(authorId);
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }
}
