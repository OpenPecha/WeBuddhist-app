import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/domain/usecases/get_series_by_id_usecase.dart';
import 'package:flutter_pecha/features/home/domain/usecases/get_series_list_usecase.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

// Watches localeProvider so series refetches when the app language changes.
final seriesListFutureProvider =
    FutureProvider<Either<Failure, List<Series>>>((ref) async {
  final language = ref.watch(contentLanguageProvider);
  final useCase = ref.watch(getSeriesListUseCaseProvider);
  return useCase(GetSeriesListParams(language: language));
});

final seriesByIdProvider = FutureProvider.autoDispose
    .family<Either<Failure, Series>, String>((ref, id) async {
  final language = ref.watch(contentLanguageProvider);
  final useCase = ref.watch(getSeriesByIdUseCaseProvider);
  return useCase(GetSeriesByIdParams(id: id, language: language));
});
