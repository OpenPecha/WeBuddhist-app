import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/data/datasource/home_local_datasource.dart';
import 'package:flutter_pecha/features/home/domain/repositories/home_repository.dart';
import '../datasource/tags_remote_datasource.dart';

class TagsRepository implements TagsRepositoryInterface {
  final TagsRemoteDatasource tagsRemoteDatasource;
  final HomeLocalDatasource local;

  TagsRepository({required this.tagsRemoteDatasource, required this.local});

  /// Get unique tags for plans
  @override
  Future<Either<Failure, List<String>>> getTags({
    required String language,
  }) async {
    final cached = local.readTags(language);
    if (cached != null) {
      unawaited(_refresh(language));
      return Right(cached);
    }

    try {
      final tags = await tagsRemoteDatasource.fetchTags(language: language);
      await local.saveTags(language, tags);
      return Right(tags);
    } catch (e) {
      return Left(_toFailure(e, 'Failed to load tags'));
    }
  }

  @override
  Stream<Either<Failure, List<String>>> watchTags({
    required String language,
  }) async* {
    final key = local.tagsKey(language);
    final cached = local.readTags(language);
    if (cached != null) yield Right(cached);

    try {
      await _refresh(language);
      final refreshed = local.readTags(language);
      if (refreshed != null) yield Right(refreshed);
    } catch (e) {
      if (cached == null) yield Left(_toFailure(e, 'Failed to load tags'));
    }

    await for (final _ in local.watchKey(key)) {
      final latest = local.readTags(language);
      if (latest != null) yield Right(latest);
    }
  }

  Future<void> _refresh(String language) async {
    final tags = await tagsRemoteDatasource.fetchTags(language: language);
    await local.saveTags(language, tags);
  }

  Failure _toFailure(Object error, String fallback) {
    if (error is ServerException) return ServerFailure(error.message);
    if (error is NetworkException) return NetworkFailure(error.message);
    if (error is AuthenticationException) {
      return AuthenticationFailure(error.message);
    }
    if (error is NotFoundException) return NotFoundFailure(error.message);
    if (error is RateLimitException) return RateLimitFailure(error.message);
    return UnknownFailure('$fallback: $error');
  }
}
