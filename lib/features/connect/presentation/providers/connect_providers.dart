import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/connect/data/datasource/connect_remote_datasource.dart';
import 'package:flutter_pecha/features/connect/data/repositories/connect_repository_impl.dart';
import 'package:flutter_pecha/features/connect/domain/repositories/connect_repository.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectRemoteDatasourceProvider = Provider<ConnectRemoteDatasource>((
  ref,
) {
  return ConnectRemoteDatasource(dio: ref.watch(dioProvider));
});

final connectRepositoryProvider = Provider<ConnectRepository>((ref) {
  return ConnectRepositoryImpl(
    remote: ref.watch(connectRemoteDatasourceProvider),
  );
});

class DiscoverGroupsState {
  final List<GroupProfile> groups;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;

  const DiscoverGroupsState({
    this.groups = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
  });

  DiscoverGroupsState copyWith({
    List<GroupProfile>? groups,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    bool clearError = false,
  }) {
    return DiscoverGroupsState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
    );
  }
}

class DiscoverGroupsNotifier extends StateNotifier<DiscoverGroupsState> {
  DiscoverGroupsNotifier({
    required this.repository,
    required this.language,
  }) : super(const DiscoverGroupsState()) {
    loadInitial();
  }

  final ConnectRepository repository;
  final String language;
  static const int _limit = 20;

  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await repository.getDiscoverGroups(
      language: language,
      skip: 0,
      limit: _limit,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (page) {
        state = state.copyWith(
          groups: page.groups,
          isLoading: false,
          hasMore: page.hasMore,
          skip: page.groups.length,
          clearError: true,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await repository.getDiscoverGroups(
      language: language,
      skip: state.skip,
      limit: _limit,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        state = state.copyWith(
          groups: [...state.groups, ...page.groups],
          isLoadingMore: false,
          hasMore: page.hasMore,
          skip: state.skip + page.groups.length,
          clearError: true,
        );
      },
    );
  }

  Future<void> refresh() async {
    state = const DiscoverGroupsState();
    await loadInitial();
  }

  void retry() {
    if (state.groups.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
  }

  void removeGroup(String groupId) {
    state = state.copyWith(
      groups: state.groups.where((g) => g.id != groupId).toList(),
    );
  }

  void addBackGroup(GroupProfile group) {
    if (state.groups.any((g) => g.id == group.id)) return;
    state = state.copyWith(
      groups: [...state.groups, group],
    );
  }
}

final discoverGroupsProvider =
    StateNotifierProvider<DiscoverGroupsNotifier, DiscoverGroupsState>(
      (ref) {
        final language = ref.watch(contentLanguageProvider);
        return DiscoverGroupsNotifier(
          repository: ref.watch(connectRepositoryProvider),
          language: language,
        );
      },
    );

class MyGroupsState {
  final List<GroupProfile> groups;
  final int total;
  final bool isLoading;
  final String? error;

  const MyGroupsState({
    this.groups = const [],
    this.total = 0,
    this.isLoading = false,
    this.error,
  });

  bool get hasGroups => groups.isNotEmpty;

  MyGroupsState copyWith({
    List<GroupProfile>? groups,
    int? total,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MyGroupsState(
      groups: groups ?? this.groups,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class MyGroupsNotifier extends StateNotifier<MyGroupsState> {
  MyGroupsNotifier({
    required this.repository,
    required this.language,
    required this.isAuthenticated,
  }) : super(const MyGroupsState()) {
    load();
  }

  final ConnectRepository repository;
  final String language;
  final bool isAuthenticated;
  static const int _limit = 20;

  Future<void> load() async {
    if (!isAuthenticated) {
      state = const MyGroupsState();
      return;
    }

    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await repository.getMyGroups(
      language: language,
      skip: 0,
      limit: _limit,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (page) {
        state = state.copyWith(
          groups: page.groups,
          total: page.total,
          isLoading: false,
          clearError: true,
        );
      },
    );
  }

  Future<void> refresh() async {
    if (!isAuthenticated) {
      state = const MyGroupsState();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await repository.getMyGroups(
      language: language,
      skip: 0,
      limit: _limit,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (page) {
        state = state.copyWith(
          groups: page.groups,
          total: page.total,
          isLoading: false,
          clearError: true,
        );
      },
    );
  }

  /// Optimistically adds a freshly joined group so the "My groups" section
  /// updates immediately, without waiting for the (eventually consistent)
  /// server to return it on the next fetch.
  void addGroup(GroupProfile group) {
    if (!isAuthenticated) return;
    if (state.groups.any((g) => g.id == group.id)) return;

    state = state.copyWith(
      groups: [group, ...state.groups],
      total: state.total + 1,
      clearError: true,
    );
  }

  /// Optimistically removes a group the user just left/unfollowed.
  void removeGroup(String groupId) {
    if (!state.groups.any((g) => g.id == groupId)) return;

    state = state.copyWith(
      groups: state.groups.where((g) => g.id != groupId).toList(),
      total: (state.total - 1).clamp(0, 1 << 31),
      clearError: true,
    );
  }
}

final myGroupsProvider =
    StateNotifierProvider<MyGroupsNotifier, MyGroupsState>((ref) {
      final authState = ref.watch(authProvider);
      final isAuthenticated = !authState.isGuest && authState.isLoggedIn;
      final language = ref.watch(contentLanguageProvider);

      return MyGroupsNotifier(
        repository: ref.watch(connectRepositoryProvider),
        language: language,
        isAuthenticated: isAuthenticated,
      );
    });
