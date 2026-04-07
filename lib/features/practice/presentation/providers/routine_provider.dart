import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_api_models.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/utils/routine_api_mapper.dart';
import 'package:flutter_pecha/features/practice/domain/usecases/routine_usecases.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches the authenticated user's routine from the API.
///
/// Returns null for guests or when no routine exists.
/// Use `ref.invalidate(userRoutineProvider)` to refresh after mutations.
final userRoutineProvider = FutureProvider<RoutineData?>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.isLoading || !auth.isLoggedIn || auth.isGuest) {
    return null;
  }

  final result = await ref.watch(getUserRoutineUseCaseProvider)(
    const GetUserRoutineParams(),
  );

  return result.fold(
    (failure) => throw Exception(failure.message),
    (response) => routineDataFromApiResponse(response),
  );
});

/// Creates a new routine with the first time block.
/// Use this provider with `.family` when creating a routine.
final createRoutineProvider =
    FutureProvider.autoDispose
        .family<RoutineWithTimeBlocksResponse, CreateTimeBlockRequest>(
  (ref, request) async {
    final result = await ref.watch(createRoutineUseCaseProvider)(
      CreateRoutineParams(request: request),
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (response) => response,
    );
  },
);

/// Creates a new time block in an existing routine.
final createTimeBlockProvider = FutureProvider.autoDispose
    .family<TimeBlockDTO, ({String routineId, CreateTimeBlockRequest request})>(
  (ref, params) async {
    final result = await ref.watch(createTimeBlockUseCaseProvider)(
      CreateTimeBlockParams(
        routineId: params.routineId,
        request: params.request,
      ),
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (dto) => dto,
    );
  },
);

/// Updates a time block (full replacement of sessions).
final updateTimeBlockProvider = FutureProvider.autoDispose.family<
    TimeBlockDTO,
    ({
      String routineId,
      String timeBlockId,
      UpdateTimeBlockRequest request
    })>(
  (ref, params) async {
    final result = await ref.watch(updateTimeBlockUseCaseProvider)(
      UpdateTimeBlockParams(
        routineId: params.routineId,
        timeBlockId: params.timeBlockId,
        request: params.request,
      ),
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (dto) => dto,
    );
  },
);

/// Deletes a time block (soft delete).
final deleteTimeBlockProvider =
    FutureProvider.autoDispose.family<void, ({String routineId, String timeBlockId})>(
  (ref, params) async {
    final result = await ref.watch(deleteTimeBlockUseCaseProvider)(
      DeleteTimeBlockParams(
        routineId: params.routineId,
        timeBlockId: params.timeBlockId,
      ),
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (_) {},
    );
  },
);
