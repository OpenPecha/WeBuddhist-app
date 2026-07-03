import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';

/// Localized label for a [RoutineItem].
///
/// Timer items derive their title from [RoutineItem.durationMs] so persisted
/// data stays locale-neutral when the app language changes.
String routineItemDisplayTitle(RoutineItem item, AppLocalizations l10n) {
  if (item.type == RoutineItemType.timer) {
    final durationMs = item.durationMs;
    if (durationMs != null && durationMs > 0) {
      return l10n.timer_minute_session(durationMs ~/ 60000);
    }
  }
  return item.title;
}
