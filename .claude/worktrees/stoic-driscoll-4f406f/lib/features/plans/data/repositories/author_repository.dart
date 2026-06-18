import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import '../datasource/author_remote_datasource.dart';
import '../models/author/author_model.dart';
import '../models/plans_model.dart';

class AuthorRepository {
  final AuthorRemoteDatasource authorRemoteDatasource;

  AuthorRepository({required this.authorRemoteDatasource});

  Future<Either<Failure, AuthorModel>> getAuthorById(String id) async {
    try {
      final result = await authorRemoteDatasource.getAuthorById(id);
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Repository error'));
    }
  }

  Future<Either<Failure, List<PlansModel>>> getPlansByAuthorId(String authorId) async {
    try {
      final result = await authorRemoteDatasource.getPlansByAuthorId(authorId);
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Repository error'));
    }
  }
}
