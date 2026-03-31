import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/texts/domain/usecases/share_usecases.dart' as domain;
import 'package:flutter_pecha/features/texts/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Share parameters model
class ShareUrlParams {
  final String textId;
  final String segmentId;
  final String language;

  const ShareUrlParams({
    required this.textId,
    required this.segmentId,
    required this.language,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareUrlParams &&
          runtimeType == other.runtimeType &&
          textId == other.textId &&
          segmentId == other.segmentId &&
          language == other.language;

  @override
  int get hashCode => textId.hashCode ^ segmentId.hashCode ^ language.hashCode;
}

// Share URL provider - returns Either<Failure, String>
final shareUrlProvider = FutureProvider.autoDispose
    .family<Either<Failure, String>, ShareUrlParams>((ref, params) async {
      final useCase = ref.watch(getShareUrlUseCaseProvider);
      return useCase(domain.ShareUrlParams(
        textId: params.textId,
        segmentId: params.segmentId,
        language: params.language,
      ));
    });
