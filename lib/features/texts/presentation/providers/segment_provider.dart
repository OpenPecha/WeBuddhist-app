import 'package:flutter_pecha/features/texts/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final segmentCommentaryFutureProvider = FutureProvider.family((
  ref,
  String segmentId,
) {
  final useCase = ref.watch(getSegmentCommentariesUseCaseProvider);
  return useCase(segmentId);
});
