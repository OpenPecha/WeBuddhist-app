import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/today_event.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

/// Re-fetches automatically when the app language changes.
final todayEventsFutureProvider =
    StreamProvider<Either<Failure, List<TodayEvent>>>((ref) {
      final language = ref.watch(contentLanguageProvider);
      final repository = ref.watch(todayEventsDomainRepositoryProvider);
      return repository.watchTodayEvents(language: language);
    });
