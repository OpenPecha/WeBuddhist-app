import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/daily_quote.dart';
import 'package:flutter_pecha/features/home/domain/entities/featured_content.dart';
import 'package:flutter_pecha/features/home/domain/entities/prayer.dart';
import 'package:flutter_pecha/features/home/domain/repositories/home_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Get daily prayer use case.
class GetDailyPrayerUseCase extends UseCase<Prayer, NoParams> {
  final HomeRepository _repository;

  GetDailyPrayerUseCase(this._repository);

  @override
  Future<Either<Failure, Prayer>> call(NoParams params) async {
    return await _repository.getDailyPrayer();
  }
}

/// Get daily quote use case.
class GetDailyQuoteUseCase extends UseCase<DailyQuote, NoParams> {
  final HomeRepository _repository;

  GetDailyQuoteUseCase(this._repository);

  @override
  Future<Either<Failure, DailyQuote>> call(NoParams params) async {
    return await _repository.getDailyQuote();
  }
}

/// Get featured content use case.
class GetFeaturedContentUseCase extends UseCase<List<FeaturedContent>, NoParams> {
  final HomeRepository _repository;

  GetFeaturedContentUseCase(this._repository);

  @override
  Future<Either<Failure, List<FeaturedContent>>> call(NoParams params) async {
    return await _repository.getFeaturedContent();
  }
}
