import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_script_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_version_detail.dart';

class ReaderSettingsRemoteDatasource {
  final Dio dio;

  ReaderSettingsRemoteDatasource({required this.dio});

  Future<ReaderLanguagesResponse> fetchLanguages({
    required String textId,
  }) async {
    final response = await dio.get('/texts/$textId/languages');
    return ReaderLanguagesResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ReaderScriptsResponse> fetchScripts({
    required String textId,
    required String language,
  }) async {
    final response =
        await dio.get('/texts/$textId/languages/$language/scripts');
    return ReaderScriptsResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ReaderVersionsResponse> fetchVersions({
    required String textId,
    required String language,
  }) async {
    final response =
        await dio.get('/texts/$textId/languages/$language/versions');
    return ReaderVersionsResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ReaderVersionDetail> fetchVersionInfo({
    required String versionId,
  }) async {
    final response = await dio.get('/texts/versions/$versionId/info');
    return ReaderVersionDetail.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
