import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

// Watches localeProvider so series refetches when the app language changes.
final seriesListFutureProvider = StreamProvider<Either<Failure, List<Series>>>((
  ref,
) {
  final language = ref.watch(contentLanguageProvider);
  final repository = ref.watch(seriesDomainRepositoryProvider);
  return repository.watchSeriesList(language: language);
});

final seriesByIdProvider = StreamProvider.autoDispose
    .family<Either<Failure, Series>, String>((ref, id) {
      final language = ref.watch(contentLanguageProvider);
      final repository = ref.watch(seriesDomainRepositoryProvider);
      return repository.watchSeriesById(id, language: language);
    });
