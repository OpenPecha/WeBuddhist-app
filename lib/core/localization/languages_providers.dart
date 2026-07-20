import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/localization/app_language.dart';
import 'package:flutter_pecha/core/localization/data/languages_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Datasource for the backend content-language list.
final languagesRemoteDatasourceProvider = Provider<LanguagesRemoteDatasource>((
  ref,
) {
  return LanguagesRemoteDatasource(dio: ref.watch(dioProvider));
});

/// Content languages the backend can serve, used to build the language picker.
///
/// Falls back to [AppLanguage.bundledFallback] on any error (offline, first
/// launch, malformed response) so the picker always has something to show. When
/// the backend returns an empty list, the bundled set is used too.
final availableContentLanguagesProvider = FutureProvider<List<AppLanguage>>((
  ref,
) async {
  try {
    final languages =
        await ref.watch(languagesRemoteDatasourceProvider).fetchLanguages();
    return languages.isNotEmpty ? languages : AppLanguage.bundledFallback;
  } catch (_) {
    return AppLanguage.bundledFallback;
  }
});
