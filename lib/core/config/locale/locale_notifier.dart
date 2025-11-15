import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_storage_keys.dart';
import 'package:flutter_pecha/core/l10n/l10n.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  final LocalStorageService _localStorageService;

  LocaleNotifier({required LocalStorageService localStorageService})
    : _localStorageService = localStorageService,
      super(const Locale("en")) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final locale = await _localStorageService.get<String>(AppStorageKeys.locale);
    if (locale != null) {
      state = Locale(locale);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final isSupported = L10n.all.any(
      (l) => l.languageCode == locale.languageCode,
    );
    if (isSupported) {
      await _localStorageService.set(AppStorageKeys.locale, locale.languageCode);
    } else {
      throw Exception("Locale ${locale.languageCode} is not supported");
    }
  }

  /// Maps onboarding language preference to app locale
  ///
  /// Onboarding uses strings like 'tibetan', 'english', 'chinese'
  /// This maps them to Flutter locale codes: 'bo', 'en', 'zh'
  Future<void> setLocaleFromOnboardingPreference(String? languagePreference) async {
    if (languagePreference == null) return;

    Locale? locale;
    switch (languagePreference.toLowerCase()) {
      case 'tibetan':
        locale = const Locale('bo');
        break;
      case 'english':
        locale = const Locale('en');
        break;
      case 'chinese':
        locale = const Locale('zh');
        break;
      default:
        // Unknown preference, don't change locale
        return;
    }

    // Only set if the locale is supported
    if (L10n.all.any((l) => l.languageCode == locale!.languageCode)) {
      await setLocale(locale);
    }
  }
}

/// Provider for managing the app's current locale
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(
    localStorageService: ref.read(localStorageServiceProvider),
  ),
);
