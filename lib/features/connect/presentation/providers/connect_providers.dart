import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/connect/data/datasource/connect_remote_datasource.dart';
import 'package:flutter_pecha/features/connect/data/repositories/connect_repository.dart';
import 'package:flutter_pecha/features/connect/domain/repositories/connect_repository.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectRemoteDatasourceProvider = Provider<ConnectRemoteDatasource>((ref) {
  return ConnectRemoteDatasource(dio: ref.watch(dioProvider));
});

final connectRepositoryProvider = Provider<ConnectRepositoryInterface>((ref) {
  return ConnectRepository(remote: ref.watch(connectRemoteDatasourceProvider));
});

final discoverGroupsProvider =
    FutureProvider.autoDispose<Either<Failure, List<GroupProfile>>>((ref) async {
  final language = ref.watch(contentLanguageProvider);
  return ref.watch(connectRepositoryProvider).getDiscoverGroups(
        language: language,
      );
});

final joinedGroupsProvider =
    FutureProvider.autoDispose<Either<Failure, List<GroupProfile>>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState.isGuest || !authState.isLoggedIn) {
    return const Right([]);
  }

  final language = ref.watch(contentLanguageProvider);
  return ref.watch(connectRepositoryProvider).getJoinedGroups(
        language: language,
      );
});

final joinedGroupIdsProvider = Provider<Set<String>>((ref) {
  final joinedAsync = ref.watch(joinedGroupsProvider);
  return joinedAsync.maybeWhen(
    data:
        (either) => either.fold(
          (_) => const {},
          (groups) => groups.map((group) => group.id).toSet(),
        ),
    orElse: () => const {},
  );
});
