import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/texts/data/models/commentary/segment_commentary_response.dart';
import 'package:flutter_pecha/features/texts/data/models/translation/segment_translation_response.dart';

class SegmentRemoteDatasource {
  final Dio dio;

  SegmentRemoteDatasource({required this.dio});

  // get all segment commentaries
  Future<SegmentCommentaryResponse> getSegmentCommentaries(
    String segmentId,
  ) async {
    final response = await dio.get('/segments/$segmentId/commentaries');
    if (response.statusCode == 200) {
      return SegmentCommentaryResponse.fromJson(response.data);
    } else {
      throw Exception('Failed to load segment commentaries');
    }
  }

  // get all translations of a segment
  Future<List<SegmentTranslationResponse>> getSegmentTranslations(
    String segmentId,
  ) async {
    final response = await dio.get('/segments/$segmentId/translations');
    if (response.statusCode == 200) {
      final List<dynamic> jsonMap = response.data as List<dynamic>;
      return jsonMap
          .map((e) => SegmentTranslationResponse.fromJson(e))
          .toList();
    } else {
      throw Exception('Failed to load segment translations');
    }
  }
}
