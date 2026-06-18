import 'package:flutter_pecha/features/texts/data/models/commentary/segment_commentary_response.dart';

/// Domain interface for segment repository.
abstract class SegmentRepositoryInterface {
  Future<SegmentCommentaryResponse> getSegmentCommentaries(String segmentId);
}
