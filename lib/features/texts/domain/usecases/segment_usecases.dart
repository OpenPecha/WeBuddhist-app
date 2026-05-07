import 'package:flutter_pecha/features/texts/data/models/commentary/segment_commentary_response.dart';
import 'package:flutter_pecha/features/texts/data/models/translation/segment_translation_response.dart';
import 'package:flutter_pecha/features/texts/domain/repositories/segment_repository.dart';

/// Use case for getting segment commentaries.
class GetSegmentCommentariesUseCase {
  final SegmentRepositoryInterface _repository;

  GetSegmentCommentariesUseCase(this._repository);

  Future<SegmentCommentaryResponse> call(String segmentId) async {
    if (segmentId.isEmpty) {
      throw ArgumentError('Segment ID cannot be empty');
    }
    return await _repository.getSegmentCommentaries(segmentId);
  }
}

/// Use case for getting segment translations.
class GetSegmentTranslationsUseCase {
  final SegmentRepositoryInterface _repository;

  GetSegmentTranslationsUseCase(this._repository);

  Future<SegmentTranslationResponse> call(String segmentId) async {
    if (segmentId.isEmpty) {
      throw ArgumentError('Segment ID cannot be empty');
    }
    return await _repository.getSegmentTranslations(segmentId);
  }
}
