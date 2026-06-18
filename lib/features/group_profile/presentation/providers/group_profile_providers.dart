import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_profile_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/repositories/group_profile_repository_impl.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/domain/usecases/get_group_profile_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

final groupProfileRemoteDatasourceProvider =
    Provider<GroupProfileRemoteDatasource>((ref) {
  return GroupProfileRemoteDatasource(dio: ref.watch(dioProvider));
});

final groupProfileRepositoryProvider =
    Provider<GroupProfileRepositoryInterface>((ref) {
  return GroupProfileRepositoryImpl(
    remote: ref.watch(groupProfileRemoteDatasourceProvider),
  );
});

final getGroupProfileUseCaseProvider =
    Provider<GetGroupProfileUseCase>((ref) {
  final repository = ref.watch(groupProfileRepositoryProvider);
  return GetGroupProfileUseCase(repository.getGroupProfile);
});

final groupProfileProvider = FutureProvider.autoDispose
    .family<Either<Failure, GroupProfile>, String>((ref, groupId) async {
  final language = ref.watch(contentLanguageProvider);
  final useCase = ref.watch(getGroupProfileUseCaseProvider);
  return useCase(
    GetGroupProfileParams(groupId: groupId, language: language),
  );
});

@immutable
class GroupFollowKey {
  final String groupId;
  final GroupType groupType;

  const GroupFollowKey({
    required this.groupId,
    required this.groupType,
  });

  @override
  bool operator ==(Object other) {
    return other is GroupFollowKey &&
        other.groupId == groupId &&
        other.groupType == groupType;
  }

  @override
  int get hashCode => Object.hash(groupId, groupType);
}

sealed class GroupFollowState {
  const GroupFollowState();
}

class GroupFollowLoading extends GroupFollowState {
  const GroupFollowLoading();
}

class GroupFollowSuccess extends GroupFollowState {
  final bool isFollowing;

  const GroupFollowSuccess({required this.isFollowing});
}

class GroupFollowFailure extends GroupFollowState {
  final Failure failure;
  const GroupFollowFailure(this.failure);
}

class GroupFollowNotifier extends StateNotifier<GroupFollowState> {
  final GroupProfileRepositoryInterface _repository;
  final Ref _ref;
  final GroupFollowKey _key;
  final bool _isAuthenticated;

  GroupFollowNotifier({
    required GroupProfileRepositoryInterface repository,
    required Ref ref,
    required GroupFollowKey key,
    required bool isAuthenticated,
  }) : _repository = repository,
       _ref = ref,
       _key = key,
       _isAuthenticated = isAuthenticated,
       super(const GroupFollowLoading()) {
    _loadInitialStatus();
  }

  void _invalidateGroupProfile() {
    _ref.invalidate(groupProfileProvider(_key.groupId));
  }

  Future<void> _loadInitialStatus() async {
    if (!_isAuthenticated) {
      if (mounted) state = const GroupFollowSuccess(isFollowing: false);
      return;
    }

    final result = await _repository.checkFollowStatus(
      _key.groupId,
      _key.groupType,
    );
    if (!mounted) return;

    result.fold(
      (_) => state = const GroupFollowSuccess(isFollowing: false),
      (isFollowing) => state = GroupFollowSuccess(isFollowing: isFollowing),
    );
  }

  Future<bool> follow() async {
    if (state is GroupFollowLoading) return false;
    state = const GroupFollowLoading();

    final result = await _repository.followGroup(
      _key.groupId,
      _key.groupType,
    );
    if (!mounted) return false;

    return await result.fold(
      (failure) async {
        state = GroupFollowFailure(failure);
        return false;
      },
      (_) async {
        state = const GroupFollowSuccess(isFollowing: true);
        _invalidateGroupProfile();
        return true;
      },
    );
  }

  Future<bool> unfollow() async {
    if (state is GroupFollowLoading) return false;
    state = const GroupFollowLoading();

    final result = await _repository.unfollowGroup(
      _key.groupId,
      _key.groupType,
    );
    if (!mounted) return false;

    return await result.fold(
      (failure) async {
        state = GroupFollowFailure(failure);
        return false;
      },
      (_) async {
        state = const GroupFollowSuccess(isFollowing: false);
        _invalidateGroupProfile();
        return true;
      },
    );
  }
}

final groupFollowProvider = StateNotifierProvider.autoDispose
    .family<GroupFollowNotifier, GroupFollowState, GroupFollowKey>((ref, key) {
  final authState = ref.watch(authProvider);
  final isAuthenticated = !authState.isGuest && authState.isLoggedIn;

  return GroupFollowNotifier(
    repository: ref.watch(groupProfileRepositoryProvider),
    ref: ref,
    key: key,
    isAuthenticated: isAuthenticated,
  );
});
