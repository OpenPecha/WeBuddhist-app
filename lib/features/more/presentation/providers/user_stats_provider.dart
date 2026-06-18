import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/more/domain/entities/user_stats.dart';
import 'package:flutter_pecha/features/more/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

final userStatsFutureProvider =
    FutureProvider<Either<Failure, UserStats>>((ref) async {
      final auth = ref.watch(authProvider);
      if (auth.isLoading || !auth.isLoggedIn || auth.isGuest) {
        return const Left(AuthenticationFailure('Not authenticated'));
      }

      final useCase = ref.watch(getUserStatsUseCaseProvider);
      return useCase(const NoParams());
    });
