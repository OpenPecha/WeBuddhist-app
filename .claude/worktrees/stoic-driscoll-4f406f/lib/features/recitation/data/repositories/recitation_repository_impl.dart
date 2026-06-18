import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitations_remote_datasource.dart';
import 'package:flutter_pecha/features/recitation/domain/content_type.dart';
import 'package:flutter_pecha/features/recitation/domain/entities/recitation.dart';
import 'package:flutter_pecha/features/recitation/domain/repositories/recitation_repository.dart';

final _logger = AppLogger('RecitationRepositoryImpl');

/// Repository implementation for managing recitations.
///
/// This implements the domain repository interface and uses the remote datasource,
/// returning Either<Failure, T> results.
class RecitationRepositoryImpl implements RecitationRepository {
  final RecitationsRemoteDatasource _datasource;

  RecitationRepositoryImpl({required RecitationsRemoteDatasource datasource})
      : _datasource = datasource;

  @override
  Future<Either<Failure, List<Recitation>>> getRecitations() async {
    try {
      final models = await _datasource.fetchRecitations(
        queryParams: RecitationsQueryParams(language: 'en'),
      );
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      _logger.error('Failed to get recitations', e);
      return Left(ExceptionMapper.map(e, context: 'getRecitations'));
    }
  }

  @override
  Future<Either<Failure, List<Recitation>>> getRecitationsByType(ContentType type) async {
    try {
      // The current API doesn't support filtering by content type
      // We'll fetch all and filter locally
      final models = await _datasource.fetchRecitations(
        queryParams: RecitationsQueryParams(language: 'en'),
      );
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      _logger.error('Failed to get recitations by type', e);
      return Left(ExceptionMapper.map(e, context: 'getRecitationsByType'));
    }
  }

  @override
  Future<Either<Failure, List<Recitation>>> getRecitationsByText(String textId) async {
    try {
      final models = await _datasource.fetchRecitations(
        queryParams: RecitationsQueryParams(language: 'en'),
      );
      final entities = models
          .where((m) => m.textId == textId)
          .map((m) => m.toEntity())
          .toList();
      return Right(entities);
    } catch (e) {
      _logger.error('Failed to get recitations by text', e);
      return Left(ExceptionMapper.map(e, context: 'getRecitationsByText'));
    }
  }

  @override
  Future<Either<Failure, List<Recitation>>> searchRecitations(String query) async {
    try {
      if (query.isEmpty) {
        return const Left(ValidationFailure('Search query cannot be empty'));
      }
      final models = await _datasource.fetchRecitations(
        queryParams: RecitationsQueryParams(
          language: 'en',
          search: query,
        ),
      );
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      _logger.error('Failed to search recitations', e);
      return Left(ExceptionMapper.map(e, context: 'searchRecitations'));
    }
  }

  @override
  Future<Either<Failure, List<Recitation>>> getSavedRecitations() async {
    try {
      final models = await _datasource.fetchSavedRecitations();
      // Sort by display order
      models.sort((a, b) {
        final orderA = a.displayOrder ?? double.maxFinite.toInt();
        final orderB = b.displayOrder ?? double.maxFinite.toInt();
        return orderA.compareTo(orderB);
      });
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      _logger.error('Failed to get saved recitations', e);
      return Left(ExceptionMapper.map(e, context: 'getSavedRecitations'));
    }
  }
}
