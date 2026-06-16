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
  final String _groupId;
  final bool _isAuthenticated;

  GroupFollowNotifier({
    required GroupProfileRepositoryInterface repository,
    required Ref ref,
    required String groupId,
    required bool isAuthenticated,
  }) : _repository = repository,
       _ref = ref,
       _groupId = groupId,
       _isAuthenticated = isAuthenticated,
       super(const GroupFollowLoading()) {
    _loadInitialStatus();
  }

  Future<void> _refreshGroupProfile() async {
    _ref.invalidate(groupProfileProvider(_groupId));
    await _ref.read(groupProfileProvider(_groupId).future);
  }

  Future<void> _loadInitialStatus() async {
    if (!_isAuthenticated) {
      if (mounted) state = const GroupFollowSuccess(isFollowing: false);
      return;
    }

    final result = await _repository.checkFollowStatus(_groupId);
    if (!mounted) return;

    result.fold(
      (_) => state = const GroupFollowSuccess(isFollowing: false),
      (isFollowing) => state = GroupFollowSuccess(isFollowing: isFollowing),
    );
  }

  Future<bool> follow() async {
    if (state is GroupFollowLoading) return false;
    state = const GroupFollowLoading();

    final result = await _repository.followGroup(_groupId);
    if (!mounted) return false;

    return await result.fold(
      (failure) async {
        state = GroupFollowFailure(failure);
        return false;
      },
      (_) async {
        state = const GroupFollowSuccess(isFollowing: true);
        await _refreshGroupProfile();
        return true;
      },
    );
  }

  Future<bool> unfollow() async {
    if (state is GroupFollowLoading) return false;
    state = const GroupFollowLoading();

    final result = await _repository.unfollowGroup(_groupId);
    if (!mounted) return false;

    return await result.fold(
      (failure) async {
        state = GroupFollowFailure(failure);
        return false;
      },
      (_) async {
        state = const GroupFollowSuccess(isFollowing: false);
        await _refreshGroupProfile();
        return true;
      },
    );
  }
}

final groupFollowProvider = StateNotifierProvider.autoDispose
    .family<GroupFollowNotifier, GroupFollowState, String>((ref, groupId) {
  final authState = ref.watch(authProvider);
  final isAuthenticated = !authState.isGuest && authState.isLoggedIn;

  return GroupFollowNotifier(
    repository: ref.watch(groupProfileRepositoryProvider),
    ref: ref,
    groupId: groupId,
    isAuthenticated: isAuthenticated,
  );
});
