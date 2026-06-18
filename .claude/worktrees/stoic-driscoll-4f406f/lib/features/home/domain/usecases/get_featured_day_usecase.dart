import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/data/models/response/featured_day_response.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Use case for getting featured day content.
///
/// This use case retrieves the featured day plan with tasks.
class GetFeaturedDayUseCase extends UseCase<FeaturedDayResponse, GetFeaturedDayParams> {
  final Future<Either<Failure, FeaturedDayResponse>> Function({String? language}) _getFeaturedDay;

  GetFeaturedDayUseCase(this._getFeaturedDay);

  @override
  Future<Either<Failure, FeaturedDayResponse>> call(GetFeaturedDayParams params) async {
    return await _getFeaturedDay(language: params.language);
  }
}

/// Parameters for GetFeaturedDayUseCase.
class GetFeaturedDayParams {
  final String? language;

  const GetFeaturedDayParams({this.language});
}
