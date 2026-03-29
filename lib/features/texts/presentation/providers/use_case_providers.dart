import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/texts/data/datasource/collections_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/data/datasource/segment_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/data/datasource/share_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/data/datasource/text_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/data/repositories/collections_repository.dart';
import 'package:flutter_pecha/features/texts/data/repositories/segment_repository.dart';
import 'package:flutter_pecha/features/texts/data/repositories/share_repository.dart';
import 'package:flutter_pecha/features/texts/data/repositories/texts_repository.dart';
import 'package:flutter_pecha/features/texts/domain/repositories/collections_repository.dart';
import 'package:flutter_pecha/features/texts/domain/repositories/segment_repository.dart';
import 'package:flutter_pecha/features/texts/domain/repositories/share_repository.dart';
import 'package:flutter_pecha/features/texts/domain/usecases/collections_usecases.dart';
import 'package:flutter_pecha/features/texts/domain/usecases/segment_usecases.dart';
import 'package:flutter_pecha/features/texts/domain/usecases/share_usecases.dart';
import 'package:flutter_pecha/features/texts/domain/usecases/text_content_usecases.dart';
import 'package:flutter_pecha/features/texts/domain/usecases/text_search_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========== Repository Providers ==========

/// Provider for the TextsRepository (data layer implementation).
final textsRepositoryProvider = Provider<TextsRepository>((ref) {
  return TextsRepository(
    remoteDatasource: TextRemoteDatasource(
      dio: ref.watch(dioProvider),
    ),
  );
});

/// Provider for the SegmentRepository implementation (domain interface).
final segmentDomainRepositoryProvider =
    Provider<SegmentRepositoryInterface>((ref) {
  return SegmentRepository(
    remoteDatasource: SegmentRemoteDatasource(dio: ref.watch(dioProvider)),
  );
});

/// Provider for the CollectionsRepository implementation (domain interface).
final collectionsDomainRepositoryProvider =
    Provider<CollectionsRepositoryInterface>((ref) {
  return CollectionsRepository(
    remoteDatasource: CollectionsRemoteDatasource(dio: ref.watch(dioProvider)),
  );
});

/// Provider for the ShareRepository implementation (domain interface).
final shareDomainRepositoryProvider =
    Provider<ShareRepositoryInterface>((ref) {
  return ShareRepository(
    remoteDatasource: ShareRemoteDatasource(dio: ref.watch(dioProvider)),
  );
});

// ========== Content Use Case Providers ==========

/// Provider for GetTextContentUseCase.
final getTextContentUseCaseProvider = Provider<GetTextContentUseCase>((ref) {
  final repository = ref.watch(textsRepositoryProvider);
  return GetTextContentUseCase(repository);
});

/// Provider for GetTextVersionUseCase.
final getTextVersionUseCaseProvider = Provider<GetTextVersionUseCase>((ref) {
  final repository = ref.watch(textsRepositoryProvider);
  return GetTextVersionUseCase(repository);
});

/// Provider for GetCommentaryTextUseCase.
final getCommentaryTextUseCaseProvider = Provider<GetCommentaryTextUseCase>((ref) {
  final repository = ref.watch(textsRepositoryProvider);
  return GetCommentaryTextUseCase(repository);
});

/// Provider for GetTextDetailsUseCase.
final getTextDetailsUseCaseProvider = Provider<GetTextDetailsUseCase>((ref) {
  final repository = ref.watch(textsRepositoryProvider);
  return GetTextDetailsUseCase(repository);
});

// ========== Search Use Case Providers ==========

/// Provider for SearchTextInTextUseCase.
final searchTextInTextUseCaseProvider = Provider<SearchTextInTextUseCase>((ref) {
  final repository = ref.watch(textsRepositoryProvider);
  return SearchTextInTextUseCase(repository);
});

/// Provider for MultilingualSearchUseCase.
final multilingualSearchUseCaseProvider = Provider<MultilingualSearchUseCase>((ref) {
  final repository = ref.watch(textsRepositoryProvider);
  return MultilingualSearchUseCase(repository);
});

/// Provider for TitleSearchUseCase.
final titleSearchUseCaseProvider = Provider<TitleSearchUseCase>((ref) {
  final repository = ref.watch(textsRepositoryProvider);
  return TitleSearchUseCase(repository);
});

/// Provider for AuthorSearchUseCase.
final authorSearchUseCaseProvider = Provider<AuthorSearchUseCase>((ref) {
  final repository = ref.watch(textsRepositoryProvider);
  return AuthorSearchUseCase(repository);
});

// ========== Segment Use Case Providers ==========

/// Provider for GetSegmentCommentariesUseCase.
final getSegmentCommentariesUseCaseProvider =
    Provider<GetSegmentCommentariesUseCase>((ref) {
  return GetSegmentCommentariesUseCase(
    ref.watch(segmentDomainRepositoryProvider),
  );
});

// ========== Collections Use Case Providers ==========

/// Provider for GetCollectionsUseCase.
final getCollectionsUseCaseProvider = Provider<GetCollectionsUseCase>((ref) {
  return GetCollectionsUseCase(ref.watch(collectionsDomainRepositoryProvider));
});

// ========== Share Use Case Providers ==========

/// Provider for GetShareUrlUseCase.
final getShareUrlUseCaseProvider = Provider<GetShareUrlUseCase>((ref) {
  return GetShareUrlUseCase(ref.watch(shareDomainRepositoryProvider));
});
