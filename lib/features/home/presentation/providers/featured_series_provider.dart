import 'dart:math';

import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/domain/usecases/get_featured_series_usecase.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

class FeaturedSeriesLayout {
  const FeaturedSeriesLayout({
    required this.featured,
    required this.others,
  });

  final Series featured;
  final List<Series> others;
}

/// Re-fetches automatically when the app language changes.
/// Picks one random series as the hero card so no single series is favored.
final featuredSeriesFutureProvider =
    FutureProvider<Either<Failure, FeaturedSeriesLayout?>>((ref) async {
  final locale = ref.watch(localeProvider);
  final useCase = ref.watch(getFeaturedSeriesUseCaseProvider);
  final result = await useCase(
    GetFeaturedSeriesParams(language: locale.languageCode),
  );

  return result.map((seriesList) {
    if (seriesList.isEmpty) return null;

    final featuredIndex = Random().nextInt(seriesList.length);
    final featured = seriesList[featuredIndex];
    final others = [
      for (var i = 0; i < seriesList.length; i++)
        if (i != featuredIndex) seriesList[i],
    ];

    return FeaturedSeriesLayout(featured: featured, others: others);
  });
});
