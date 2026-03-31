import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/plans_usecases.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final plansByTagProvider = FutureProvider.family<Either<Failure, List<Plan>>, String>((ref, tag) async {
  final locale = ref.watch(localeProvider);
  final languageCode = locale.languageCode;
  final getPlansUseCase = ref.watch(getPlansUseCaseProvider);

  return getPlansUseCase(GetPlansParams(
    language: languageCode,
    tag: tag,
  ));
});
