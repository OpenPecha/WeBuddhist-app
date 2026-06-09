import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
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
  final locale = ref.watch(localeProvider);
  final useCase = ref.watch(getGroupProfileUseCaseProvider);
  return useCase(
    GetGroupProfileParams(groupId: groupId, language: locale.languageCode),
  );
});

sealed class GroupFollowState {
  const GroupFollowState();
}

class GroupFollowIdle extends GroupFollowState {
  const GroupFollowIdle();
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

  GroupFollowNotifier({
    required GroupProfileRepositoryInterface repository,
    required Ref ref,
    required String groupId,
  }) : _repository = repository,
       _ref = ref,
       _groupId = groupId,
       super(const GroupFollowIdle());

  Future<bool> follow() async {
    if (state is GroupFollowLoading) return false;
    state = const GroupFollowLoading();

    final result = await _repository.followGroup(_groupId);
    if (!mounted) return false;

    return result.fold(
      (failure) {
        state = GroupFollowFailure(failure);
        return false;
      },
      (_) {
        state = const GroupFollowSuccess(isFollowing: true);
        _ref.invalidate(groupProfileProvider(_groupId));
        return true;
      },
    );
  }

  Future<bool> unfollow() async {
    if (state is GroupFollowLoading) return false;
    state = const GroupFollowLoading();

    final result = await _repository.unfollowGroup(_groupId);
    if (!mounted) return false;

    return result.fold(
      (failure) {
        state = GroupFollowFailure(failure);
        return false;
      },
      (_) {
        state = const GroupFollowSuccess(isFollowing: false);
        _ref.invalidate(groupProfileProvider(_groupId));
        return true;
      },
    );
  }
}

final groupFollowProvider = StateNotifierProvider.autoDispose
    .family<GroupFollowNotifier, GroupFollowState, String>((ref, groupId) {
  return GroupFollowNotifier(
    repository: ref.watch(groupProfileRepositoryProvider),
    ref: ref,
    groupId: groupId,
  );
});
