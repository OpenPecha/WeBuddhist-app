import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
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
    if (languages.isEmpty) return AppLanguage.bundledFallback;

    // Authoritative response: enforce the server-side kill switch so a
    // previously-stored language the backend has disabled stops being sent.
    // Only runs on this success path — never against the offline fallback.
    await ref
        .read(contentLanguageProvider.notifier)
        .reconcileToAvailable(languages.map((l) => l.code).toList());

    return languages;
  } catch (_) {
    return AppLanguage.bundledFallback;
  }
});
