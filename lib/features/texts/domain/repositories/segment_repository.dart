import 'package:flutter_pecha/features/texts/data/models/commentary/segment_commentary_response.dart';
import 'package:flutter_pecha/features/texts/data/models/segment_detail_with_text.dart';
import 'package:flutter_pecha/features/texts/data/models/translation/segment_translation_response.dart';

/// Domain interface for segment repository.
abstract class SegmentRepositoryInterface {
  Future<SegmentDetailWithText> getSegmentWithTextDetails(String segmentId);
  Future<SegmentCommentaryResponse> getSegmentCommentaries(String segmentId);
  Future<SegmentTranslationResponse> getSegmentTranslations(String segmentId);
}
