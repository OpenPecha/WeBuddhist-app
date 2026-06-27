import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/more/domain/entities/series_day_completed.dart';
import 'package:flutter_pecha/features/more/domain/usecases/get_series_day_completed_usecase.dart';
import 'package:flutter_pecha/features/more/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

final seriesDayCompletedProvider =
    FutureProvider.autoDispose<Either<Failure, SeriesDayCompletedPage>>((
      ref,
    ) async {
      final auth = ref.watch(authProvider);
      if (auth.isLoading || !auth.isLoggedIn || auth.isGuest) {
        return const Left(AuthenticationFailure('Not authenticated'));
      }

      final language = ref.watch(contentLanguageProvider);
      final useCase = ref.watch(getSeriesDayCompletedUseCaseProvider);
      return useCase(GetSeriesDayCompletedParams(language: language));
    });
