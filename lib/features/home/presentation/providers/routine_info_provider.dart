import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/home/domain/entities/routine_info.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

final routineInfoFutureProvider = StreamProvider<Either<Failure, RoutineInfo>>((
  ref,
) {
  final auth = ref.watch(authProvider);
  if (auth.isLoading || !auth.isLoggedIn || auth.isGuest) {
    return Stream.value(const Left(AuthenticationFailure('Not authenticated')));
  }

  final repository = ref.watch(routineInfoDomainRepositoryProvider);
  return repository.watchRoutineInfo();
});
