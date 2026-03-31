import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Use case for getting tags.
///
/// This use case retrieves a list of unique tags for filtering plans.
class GetTagsUseCase extends UseCase<List<String>, GetTagsParams> {
  final Future<Either<Failure, List<String>>> Function({required String language}) _getTags;

  GetTagsUseCase(this._getTags);

  @override
  Future<Either<Failure, List<String>>> call(GetTagsParams params) async {
    return await _getTags(language: params.language);
  }
}

/// Parameters for GetTagsUseCase.
class GetTagsParams {
  final String language;

  const GetTagsParams({required this.language});
}
