import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/more/domain/entities/user_stats.dart';
import 'package:flutter_pecha/features/more/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

final userStatsFutureProvider = StreamProvider<Either<Failure, UserStats>>((
  ref,
) {
  final auth = ref.watch(authProvider);
  if (auth.isLoading || !auth.isLoggedIn || auth.isGuest) {
    return Stream.value(const Left(AuthenticationFailure('Not authenticated')));
  }

  final repository = ref.watch(userStatsRepositoryProvider);
  return repository.watchUserStats();
});
