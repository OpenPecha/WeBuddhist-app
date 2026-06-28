import 'dart:async';

import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/domain/repositories/mala_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for accumulation (preset) search.
class AccumulationSearchState {
  final String query;
  final List<Mantra> results;
  final bool isLoading;
  final String? error;

  const AccumulationSearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  AccumulationSearchState copyWith({
    String? query,
    List<Mantra>? results,
    bool? isLoading,
    String? error,
  }) {
    return AccumulationSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// StateNotifier for managing accumulation search with debounce.
class AccumulationSearchNotifier
    extends StateNotifier<AccumulationSearchState> {
  final MalaRepository repository;
  final String languageCode;
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  AccumulationSearchNotifier({
    required this.repository,
    required this.languageCode,
  }) : super(const AccumulationSearchState());

  /// Search with debounce.
  void search(String query) {
    _debounceTimer?.cancel();

    // Update query immediately for UI feedback.
    state = state.copyWith(query: query, isLoading: true, error: null);

    if (query.trim().isEmpty) {
      state = const AccumulationSearchState();
      return;
    }

    _debounceTimer = Timer(_debounceDuration, () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      state = const AccumulationSearchState();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await repository.getCatalogue(
      language: languageCode,
      search: query.trim(),
    );

    result.fold(
      (failure) {
        if (mounted) {
          state = state.copyWith(isLoading: false, error: failure.message);
        }
      },
      (results) {
        if (mounted) {
          state = state.copyWith(
            results: results,
            isLoading: false,
            error: null,
          );
        }
      },
    );
  }

  /// Retry the current search.
  void retry() {
    if (state.query.isNotEmpty) {
      _performSearch(state.query);
    }
  }

  /// Clear search state.
  void clear() {
    _debounceTimer?.cancel();
    state = const AccumulationSearchState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
