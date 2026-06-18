import 'package:flutter_pecha/features/texts/data/datasource/segment_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/data/models/commentary/segment_commentary_response.dart';
import 'package:flutter_pecha/features/texts/domain/repositories/segment_repository.dart';

class SegmentRepository implements SegmentRepositoryInterface {
  final SegmentRemoteDatasource remoteDatasource;

  SegmentRepository({required this.remoteDatasource});

  @override
  Future<SegmentCommentaryResponse> getSegmentCommentaries(
    String segmentId,
  ) async {
    return await remoteDatasource.getSegmentCommentaries(segmentId);
  }
}
