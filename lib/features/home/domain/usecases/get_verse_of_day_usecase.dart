import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

class GetVerseOfDayUseCase extends UseCase<VerseOfDay, GetVerseOfDayParams> {
  final Future<Either<Failure, VerseOfDay>> Function({required String language})
      _getVerseOfDay;

  GetVerseOfDayUseCase(this._getVerseOfDay);

  @override
  Future<Either<Failure, VerseOfDay>> call(GetVerseOfDayParams params) async {
    return await _getVerseOfDay(language: params.language);
  }
}

class GetVerseOfDayParams {
  final String language;

  const GetVerseOfDayParams({required this.language});
}
