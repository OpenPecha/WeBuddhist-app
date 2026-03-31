import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/usecases/get_tags_usecase.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Tags provider - returns Either<Failure, List<String>>
// Watches localeProvider to refresh when language changes
final tagsFutureProvider = FutureProvider<Either<Failure, List<String>>>((ref) async {
  final locale = ref.watch(localeProvider);
  final useCase = ref.watch(getTagsUseCaseProvider);

  return useCase(GetTagsParams(language: locale.languageCode));
});
