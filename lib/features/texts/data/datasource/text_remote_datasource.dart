import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/features/texts/data/models/search/multilingual_search_response.dart';
import 'package:flutter_pecha/features/texts/data/models/search/search_response.dart';
import 'package:flutter_pecha/features/texts/data/models/search/title_search_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/commentary_text_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/detail_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/toc_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/version_response.dart';

/// Text remote datasource.
///
/// Error handling is centralized in ErrorInterceptor, which converts
/// DioExceptions to typed AppExceptions. Exceptions propagate naturally
/// to the repository layer for mapping to Failures.
class TextRemoteDatasource {
  final Dio dio;
  final String baseUrl = dotenv.env['BASE_API_URL']!;

  TextRemoteDatasource({required this.dio});

  // to get the texts
  Future<TextDetailResponse> fetchTexts({
    required String termId,
    String? language,
    int skip = 0,
    int limit = 20,
  }) async {
    final response = await dio.get(
      '/texts',
      queryParameters: {
        'collection_id': termId,
        if (language != null) 'language': language,
        'skip': skip,
        'limit': limit,
      },
    );

    return TextDetailResponse.fromJson(response.data);
  }

  // get the content of the text
  Future<TocResponse> fetchTextContent({
    required String textId,
    String? language,
  }) async {
    final response = await dio.get(
      '/texts/$textId/contents',
      queryParameters: {'language': language ?? 'en'},
    );

    return TocResponse.fromJson(response.data);
  }

  // get the version of the text
  Future<VersionResponse> fetchTextVersion({
    required String textId,
    String? language,
  }) async {
    final response = await dio.get(
      '/texts/$textId/versions',
      queryParameters: {'language': language ?? 'en'},
    );

    return VersionResponse.fromJson(response.data);
  }

  // get the commentary text of the text
  Future<CommentaryTextResponse> fetchCommentaryText({
    required String textId,
    String? language,
  }) async {
    final response = await dio.get(
      '/texts/$textId/commentaries',
      queryParameters: {'language': language ?? 'en'},
    );

    return CommentaryTextResponse.fromJson(response.data);
  }

  // post request to get the details of the text
  Future<ReaderResponse> fetchTextDetails({
    required String textId,
    String? contentId,
    String? versionId,
    String? segmentId,
    String? direction,
  }) async {
    final response = await dio.post(
      '/texts/$textId/details',
      data: {
        if (contentId != null) 'content_id': contentId,
        if (segmentId != null) 'segment_id': segmentId,
        'direction': direction,
      },
    );

    return ReaderResponse.fromJson(response.data);
  }

  // search the text by query
  Future<SearchResponse> searchText({
    required String query,
    String? language,
    String? textId,
  }) async {
    final response = await dio.get(
      '/search',
      queryParameters: {
        'query': query,
        'search_type': 'SOURCE',
        if (language != null) 'language': language,
        if (textId != null) 'text_id': textId,
      },
    );

    return SearchResponse.fromJson(response.data);
  }

  // multilingual search
  Future<MultilingualSearchResponse> multilingualSearch({
    required String query,
    String? language,
    String? textId,
  }) async {
    final response = await dio.get(
      '/search/multilingual',
      queryParameters: {
        'query': query,
        'search_type': 'exact',
        if (language != null) 'language': language,
        if (textId != null) 'text_id': textId,
      },
    );

    return MultilingualSearchResponse.fromJson(response.data);
  }

  // title search
  Future<TitleSearchResponse> titleSearch({
    String? title,
    String? author,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await dio.get(
      '/texts/title-search',
      queryParameters: {
        if (title != null && title.isNotEmpty) 'title': title,
        if (author != null && author.isNotEmpty) 'author': author,
        'limit': limit,
        'offset': offset,
      },
    );

    final jsonList = response.data as List<dynamic>;
    return TitleSearchResponse.fromJson(
      jsonList,
      total: jsonList.length,
      limit: limit,
      offset: offset,
    );
  }

  // author search - uses same endpoint as title search but with author parameter
  Future<TitleSearchResponse> authorSearch({
    String? author,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await dio.get(
      '/texts/title-search',
      queryParameters: {
        if (author != null && author.isNotEmpty) 'author': author,
        'limit': limit,
        'offset': offset,
      },
    );

    final jsonList = response.data as List<dynamic>;
    return TitleSearchResponse.fromJson(
      jsonList,
      total: jsonList.length,
      limit: limit,
      offset: offset,
    );
  }
}
