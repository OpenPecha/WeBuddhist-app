/// Domain interface for share repository.
abstract class ShareRepositoryInterface {
  Future<String> getShareUrl({
    required String textId,
    required String segmentId,
    required String language,
  });
}
