import 'package:flutter_pecha/core/network/api_client_provider.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/practice/data/datasource/routine_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_api_models.dart';
import 'package:flutter_pecha/features/practice/data/repositories/routine_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Infrastructure providers ───

final routineRemoteDatasourceProvider = Provider<RoutineRemoteDatasource>((ref) {
  return RoutineRemoteDatasource(client: ref.watch(apiClientProvider));
});

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return RoutineRepository(
    remoteDatasource: ref.watch(routineRemoteDatasourceProvider),
  );
});

// ─── Data providers ───

/// Fetches the authenticated user's routine from the API (null = no routine yet).
/// Use `ref.invalidate(userRoutineProvider)` to refresh after mutations.
final userRoutineProvider = FutureProvider<RoutineResponse?>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.isLoading || !auth.isLoggedIn || auth.isGuest) {
    return null;
  }
  return ref.watch(routineRepositoryProvider).getUserRoutine();
});

/// Creates a new routine with the first time block.
/// Returns the created routine with time blocks.
final createRoutineProvider =
    FutureProvider.family<RoutineWithTimeBlocksResponse, CreateTimeBlockRequest>(
  (ref, request) {
    return ref.read(routineRepositoryProvider).createRoutineWithTimeBlock(request);
  },
);

/// Creates a new time block in an existing routine.
final createTimeBlockProvider =
    FutureProvider.family<TimeBlockDTO, ({String routineId, CreateTimeBlockRequest request})>(
  (ref, params) {
    return ref
        .read(routineRepositoryProvider)
        .createTimeBlock(params.routineId, params.request);
  },
);

/// Updates a time block (full replacement of sessions).
final updateTimeBlockProvider = FutureProvider.family<
    TimeBlockDTO,
    ({String routineId, String timeBlockId, UpdateTimeBlockRequest request})>(
  (ref, params) {
    return ref.read(routineRepositoryProvider).updateTimeBlock(
          params.routineId,
          params.timeBlockId,
          params.request,
        );
  },
);

/// Deletes a time block (soft delete).
final deleteTimeBlockProvider =
    FutureProvider.family<void, ({String routineId, String timeBlockId})>(
  (ref, params) {
    return ref
        .read(routineRepositoryProvider)
        .deleteTimeBlock(params.routineId, params.timeBlockId);
  },
);
