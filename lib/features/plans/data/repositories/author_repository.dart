import '../datasource/author_remote_datasource.dart';
import '../../models/author_model.dart';

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

  Future<AuthorModel> createAuthor(AuthorModel author) async {
    try {
      return await authorRemoteDatasource.createAuthor(author);
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  Future<AuthorModel> updateAuthor(String id, AuthorModel author) async {
    try {
      return await authorRemoteDatasource.updateAuthor(id, author);
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  Future<void> deleteAuthor(String id) async {
    try {
      await authorRemoteDatasource.deleteAuthor(id);
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }
}
