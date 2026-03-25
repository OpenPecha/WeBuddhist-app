import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/texts/data/models/search/multilingual_search_response.dart';
import 'package:flutter_pecha/features/texts/data/models/search/search_response.dart';
import 'package:flutter_pecha/features/texts/data/models/search/title_search_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/commentary_text_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/detail_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/toc_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/version_response.dart';

class TextRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('TextRemoteDatasource');
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

    if (response.statusCode == 200) {
      return TextDetailResponse.fromJson(response.data);
    } else {
      throw Exception('Failed to load texts');
    }
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

    if (response.statusCode == 200) {
      return TocResponse.fromJson(response.data);
    } else {
      _logger.error('Failed to load text content: ${response.data}');
      throw Exception('Failed to load text content');
    }
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

    if (response.statusCode == 200) {
      return VersionResponse.fromJson(response.data);
    } else {
      _logger.error('Failed to load text version: ${response.data}');
      throw Exception('Failed to load text version');
    }
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
    if (response.statusCode == 200) {
      return CommentaryTextResponse.fromJson(response.data);
    } else {
      _logger.error('Failed to load commentary text: ${response.data}');
      throw Exception('Failed to load commentary text');
    }
  }

  // post request to get the details of the text
  Future<ReaderResponse> fetchTextDetails({
    required String textId,
    String? contentId,
    String? versionId,
    String? segmentId,
    String? direction,
  }) async {
    try {
      final response = await dio.post(
        '/texts/$textId/details',
        data: {
          if (contentId != null) 'content_id': contentId,
          if (segmentId != null) 'segment_id': segmentId,
          'direction': direction,
        },
      );

      if (response.statusCode == 200) {
        return ReaderResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to load text details ::: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to load text details ????? $e');
    }
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
    if (response.statusCode == 200) {
      return SearchResponse.fromJson(response.data);
    } else {
      throw Exception('Failed to search text');
    }
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
    if (response.statusCode == 200) {
      return MultilingualSearchResponse.fromJson(response.data);
    } else {
      throw Exception('MultilingualSearchResponse::: Failed to search text');
    }
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

    if (response.statusCode == 200) {
      final jsonList = response.data as List<dynamic>;
      return TitleSearchResponse.fromJson(
        jsonList,
        total: jsonList.length,
        limit: limit,
        offset: offset,
      );
    } else {
      _logger.error('TitleSearchResponse::: Failed to search titles: ${response.statusCode}');
      throw Exception('TitleSearchResponse::: Failed to search titles');
    }
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

    if (response.statusCode == 200) {
      final jsonList = response.data as List<dynamic>;
      return TitleSearchResponse.fromJson(
        jsonList,
        total: jsonList.length,
        limit: limit,
        offset: offset,
      );
    } else {
      _logger.error('AuthorSearchResponse::: Failed to search authors: ${response.statusCode}');
      throw Exception('AuthorSearchResponse::: Failed to search authors');
    }
  }
}
