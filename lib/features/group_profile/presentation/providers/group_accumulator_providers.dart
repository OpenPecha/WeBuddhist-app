import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_accumulator_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/repositories/group_accumulator_repository_impl.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_accumulator_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

final groupAccumulatorRemoteDatasourceProvider =
    Provider<GroupAccumulatorRemoteDatasource>((ref) {
      return GroupAccumulatorRemoteDatasource(dio: ref.watch(dioProvider));
    });

final groupAccumulatorRepositoryProvider =
    Provider<GroupAccumulatorRepositoryInterface>((ref) {
      return GroupAccumulatorRepositoryImpl(
        remote: ref.watch(groupAccumulatorRemoteDatasourceProvider),
      );
    });

final groupAccumulatorsProvider = FutureProvider.autoDispose
    .family<Either<Failure, GroupAccumulatorsPage>, String>((
      ref,
      groupId,
    ) async {
      ref.watch(authProvider);
      final repository = ref.watch(groupAccumulatorRepositoryProvider);
      return repository.getGroupAccumulators(groupId, skip: 0, limit: 20);
    });

final groupAccumulatorDetailProvider = FutureProvider.autoDispose
    .family<Either<Failure, GroupAccumulatorDetail>, String>((
      ref,
      accumulatorId,
    ) async {
      ref.watch(authProvider);
      final repository = ref.watch(groupAccumulatorRepositoryProvider);
      return repository.getGroupAccumulator(accumulatorId);
    });

@immutable
class GroupAccumulatorMembersKey {
  final String accumulatorId;
  final GroupAccumulatorMemberSort sortBy;

  const GroupAccumulatorMembersKey({
    required this.accumulatorId,
    required this.sortBy,
  });

  @override
  bool operator ==(Object other) {
    return other is GroupAccumulatorMembersKey &&
        other.accumulatorId == accumulatorId &&
        other.sortBy == sortBy;
  }

  @override
  int get hashCode => Object.hash(accumulatorId, sortBy);
}

class GroupAccumulatorMembersState {
  final List<GroupAccumulatorMember> members;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final Failure? error;

  const GroupAccumulatorMembersState({
    this.members = const [],
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  bool get hasMore => members.length < total;

  GroupAccumulatorMembersState copyWith({
    List<GroupAccumulatorMember>? members,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    Failure? error,
    bool clearError = false,
  }) {
    return GroupAccumulatorMembersState(
      members: members ?? this.members,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GroupAccumulatorMembersNotifier
    extends StateNotifier<GroupAccumulatorMembersState> {
  GroupAccumulatorMembersNotifier({
    required GroupAccumulatorRepositoryInterface repository,
    required this.accumulatorId,
    required this.sortBy,
  }) : _repository = repository,
       super(const GroupAccumulatorMembersState());

  final GroupAccumulatorRepositoryInterface _repository;
  final String accumulatorId;
  final GroupAccumulatorMemberSort sortBy;
  static const _pageSize = 20;
  bool _hasLoaded = false;

  Future<void> loadInitial({bool force = false}) async {
    if (_hasLoaded && !force) return;
    _hasLoaded = true;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getGroupAccumulatorMembers(
      accumulatorId,
      skip: 0,
      limit: _pageSize,
      sortBy: sortBy,
    );

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure),
      (page) => state = state.copyWith(
        isLoading: false,
        members: page.members,
        total: page.total,
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);
    final result = await _repository.getGroupAccumulatorMembers(
      accumulatorId,
      skip: state.members.length,
      limit: _pageSize,
      sortBy: sortBy,
    );

    result.fold(
      (failure) => state = state.copyWith(isLoadingMore: false, error: failure),
      (page) => state = state.copyWith(
        isLoadingMore: false,
        members: [...state.members, ...page.members],
        total: page.total,
      ),
    );
  }

  Future<void> retry() async {
    _hasLoaded = false;
    await loadInitial(force: true);
  }
}

final groupAccumulatorMembersProvider = StateNotifierProvider.autoDispose
    .family<
      GroupAccumulatorMembersNotifier,
      GroupAccumulatorMembersState,
      GroupAccumulatorMembersKey
    >((ref, key) {
      return GroupAccumulatorMembersNotifier(
        repository: ref.watch(groupAccumulatorRepositoryProvider),
        accumulatorId: key.accumulatorId,
        sortBy: key.sortBy,
      );
    });

Future<bool> joinGroupAccumulator({
  required WidgetRef ref,
  required String accumulatorId,
  required String groupId,
}) async {
  final repository = ref.read(groupAccumulatorRepositoryProvider);
  final result = await repository.joinGroupAccumulator(accumulatorId);
  return result.fold((_) => false, (_) {
    ref.invalidate(groupAccumulatorsProvider(groupId));
    ref.invalidate(groupAccumulatorDetailProvider(accumulatorId));
    return true;
  });
}
