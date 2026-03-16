import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';

/// Extension on [BuildContext] to provide safe access to [AppLocalizations]
///
/// Usage:
/// ```dart
/// // Instead of:
/// AppLocalizations.of(context)!
///
/// // Use:
/// context.l10n
/// ```
extension BuildContextExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
