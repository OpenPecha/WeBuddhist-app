import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/data/datasource/verse_of_day_remote_datasource.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day.dart';
import 'package:flutter_pecha/features/home/domain/repositories/home_repository.dart';

class VerseOfDayRepository implements VerseOfDayRepositoryInterface {
  final VerseOfDayRemoteDatasource remote;

  VerseOfDayRepository({required this.remote});

  @override
  Future<Either<Failure, VerseOfDay>> getVerseOfDay({
    required String language,
  }) async {
    try {
      final model = await remote.fetchVerseOfDay(language: language);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to get verse of day: $e'));
    }
  }
}
