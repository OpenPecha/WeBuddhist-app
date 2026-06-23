import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/more/domain/entities/mantra_count.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

class GetMantraCountsParams extends Equatable {
  final String language;
  final int skip;
  final int limit;

  const GetMantraCountsParams({
    required this.language,
    this.skip = 0,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [language, skip, limit];
}

class GetMantraCountsUseCase extends UseCase<MantraCountPage, GetMantraCountsParams> {
  final Future<Either<Failure, MantraCountPage>> Function(
    GetMantraCountsParams params,
  ) _getMantraCounts;

  GetMantraCountsUseCase(this._getMantraCounts);

  @override
  Future<Either<Failure, MantraCountPage>> call(GetMantraCountsParams params) {
    return _getMantraCounts(params);
  }
}
