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
}

final discoverGroupsProvider =
    StateNotifierProvider.autoDispose<DiscoverGroupsNotifier, DiscoverGroupsState>(
      (ref) {
        final language = ref.watch(contentLanguageProvider);
        return DiscoverGroupsNotifier(
          repository: ref.watch(connectRepositoryProvider),
          language: language,
        );
      },
    );
