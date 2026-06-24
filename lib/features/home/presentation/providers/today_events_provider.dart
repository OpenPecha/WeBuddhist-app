import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/today_event.dart';
import 'package:flutter_pecha/features/home/domain/usecases/get_today_events_usecase.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

/// Re-fetches automatically when the app language changes.
final todayEventsFutureProvider =
    FutureProvider<Either<Failure, List<TodayEvent>>>((ref) async {
      final language = ref.watch(contentLanguageProvider);
      final useCase = ref.watch(getTodayEventsUseCaseProvider);
      return useCase(GetTodayEventsParams(language: language));
    });
