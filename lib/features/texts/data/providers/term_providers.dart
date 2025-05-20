// lib/features/texts/data/providers/term_providers.dart
import 'package:flutter_pecha/features/texts/data/datasource/term_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../repositories/term_repository.dart';
import 'package:flutter_pecha/core/config/locale_provider.dart';

final termRepositoryProvider = Provider(
  (ref) => TermRepository(
    remoteDatasource: TermRemoteDatasource(client: http.Client()),
  ),
);

final termListFutureProvider = FutureProvider((ref) {
  final locale = ref.watch(localeProvider);
  final languageCode = locale?.languageCode;
  return ref.watch(termRepositoryProvider).getTerms(language: languageCode);
});
