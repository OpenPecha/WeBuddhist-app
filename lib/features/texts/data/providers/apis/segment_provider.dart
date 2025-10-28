import 'package:flutter_pecha/core/network/api_client_provider.dart';
import 'package:flutter_pecha/features/texts/data/datasource/segment_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/data/repositories/segment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final segmentRepositoryProvider = Provider<SegmentRepository>(
  (ref) => SegmentRepository(
    remoteDatasource: SegmentRemoteDatasource(
      client: ref.watch(apiClientProvider),
    ),
  ),
);

final segmentCommentaryFutureProvider = FutureProvider.family((
  ref,
  String segmentId,
) {
  return ref.watch(segmentRepositoryProvider).getSegmentCommentaries(segmentId);
});
