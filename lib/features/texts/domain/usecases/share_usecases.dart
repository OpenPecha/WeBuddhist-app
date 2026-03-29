import 'package:flutter_pecha/features/texts/domain/repositories/share_repository.dart';

/// Use case for generating a share URL.
class GetShareUrlUseCase {
  final ShareRepositoryInterface _repository;

  GetShareUrlUseCase(this._repository);

  Future<String> call(ShareUrlParams params) async {
    if (params.textId.isEmpty || params.segmentId.isEmpty || params.language.isEmpty) {
      throw ArgumentError('All share parameters must be non-empty');
    }
    return await _repository.getShareUrl(
      textId: params.textId,
      segmentId: params.segmentId,
      language: params.language,
    );
  }
}

class ShareUrlParams {
  final String textId;
  final String segmentId;
  final String language;

  const ShareUrlParams({
    required this.textId,
    required this.segmentId,
    required this.language,
  });
}
