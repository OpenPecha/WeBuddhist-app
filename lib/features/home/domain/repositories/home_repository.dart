import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/daily_quote.dart';
import 'package:flutter_pecha/features/home/domain/entities/featured_content.dart';
import 'package:flutter_pecha/features/home/domain/entities/prayer.dart';
import 'package:flutter_pecha/shared/domain/base_classes/repository.dart';

/// Home repository interface.
abstract class HomeRepository extends Repository {
  /// Get daily prayer.
  Future<Either<Failure, Prayer>> getDailyPrayer();

  /// Get daily quote/verse.
  Future<Either<Failure, DailyQuote>> getDailyQuote();

  /// Get featured content.
  Future<Either<Failure, List<FeaturedContent>>> getFeaturedContent();

  /// Get content for a specific tag.
  Future<Either<Failure, List<FeaturedContent>>> getContentByTag(String tagId);
}
