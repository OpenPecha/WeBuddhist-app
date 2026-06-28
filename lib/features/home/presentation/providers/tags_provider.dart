import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Tags provider - returns Either<Failure, List<String>>
// Watches localeProvider to refresh when language changes
final tagsFutureProvider = StreamProvider<Either<Failure, List<String>>>((ref) {
  final language = ref.watch(contentLanguageProvider);
  final repository = ref.watch(tagsDomainRepositoryProvider);
  return repository.watchTags(language: language);
});
