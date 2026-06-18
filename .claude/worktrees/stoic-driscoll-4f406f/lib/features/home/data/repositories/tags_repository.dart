import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/repositories/home_repository.dart';
import '../datasource/tags_remote_datasource.dart';

class TagsRepository implements TagsRepositoryInterface {
  final TagsRemoteDatasource tagsRemoteDatasource;

  TagsRepository({required this.tagsRemoteDatasource});

  /// Get unique tags for plans
  @override
  Future<Either<Failure, List<String>>> getTags({required String language}) async {
    try {
      final tags = await tagsRemoteDatasource.fetchTags(language: language);
      return Right(tags);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load tags: $e'));
    }
  }
}
