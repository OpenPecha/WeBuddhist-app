import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// A locale name safe to pass to `intl`'s [DateFormat] and [NumberFormat].
///
/// `intl` ships no date/number symbol data for some app locales (notably `bo`,
/// Tibetan), so `NumberFormat.decimalPattern('bo')` throws
/// `Invalid locale "bo"`. We fall back to `en` when the active locale is
/// unsupported — mirroring what [MaterialLocalizationsBo] does for Material
/// widgets.
String intlFormatLocale(String locale) {
  final canonical = Intl.canonicalizedLocale(locale);
  return DateFormat.localeExists(canonical) ? canonical : 'en';
}

/// [intlFormatLocale] for the active [BuildContext] locale.
String intlFormatLocaleOf(BuildContext context) {
  return intlFormatLocale(Localizations.localeOf(context).toString());
}
