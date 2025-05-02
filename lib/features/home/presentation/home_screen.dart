// This file contains the presentation layer for the home screen feature.
// It handles the UI for the main home screen after splash.

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/theme/theme_provider.dart';
import 'package:flutter_pecha/core/config/locale_provider.dart';

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  final _supportedLocales = const [Locale('en'), Locale('zh'), Locale('bo')];

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'zh':
        return '中文 (Chinese)';
      case 'bo':
        return 'བོད་སྐད་ (Tibetan)';
      default:
        return locale.languageCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(localizations.appTitle),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                localizations.pechaHeading,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
              Text(
                localizations.learnLiveShare,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              IconButton(
                iconSize: 36,
                icon: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip:
                    themeMode == ThemeMode.dark
                        ? localizations.switchToLight
                        : localizations.switchToDark,
                onPressed: () {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
              ),
              Text(
                themeMode == ThemeMode.dark
                    ? localizations.themeDark
                    : localizations.themeLight,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              DropdownButton<Locale>(
                value: locale ?? Localizations.localeOf(context),
                items:
                    _supportedLocales.map((localeItem) {
                      return DropdownMenuItem<Locale>(
                        value: localeItem,
                        child: Text(_getLanguageName(localeItem)),
                      );
                    }).toList(),
                onChanged: (Locale? newLocale) {
                  ref.read(localeProvider.notifier).setLocale(newLocale);
                },
                underline: Container(
                  height: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text('Language', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
