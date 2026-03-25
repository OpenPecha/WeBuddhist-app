import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/texts/data/datasource/segment_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/data/repositories/segment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final segmentRepositoryProvider = Provider<SegmentRepository>(
  (ref) => SegmentRepository(
    remoteDatasource: SegmentRemoteDatasource(
      dio: ref.watch(dioProvider),
    ),
  ),
);

final segmentCommentaryFutureProvider = FutureProvider.family((
  ref,
  String segmentId,
) {
  return ref.watch(segmentRepositoryProvider).getSegmentCommentaries(segmentId);
});
