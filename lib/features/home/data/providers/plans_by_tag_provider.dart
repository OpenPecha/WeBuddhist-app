import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/plans/data/providers/plans_providers.dart';

final plansByTagProvider = FutureProvider.family<List<PlansModel>, String>((
  ref,
  tag,
) {
  final locale = ref.watch(localeProvider);
  final languageCode = locale.languageCode;
  return ref
      .watch(plansRepositoryProvider)
      .getPlans(language: languageCode, tag: tag);
});
