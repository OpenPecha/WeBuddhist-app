import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/onboarding/application/tradition_selection_state.dart';
import 'package:flutter_pecha/features/onboarding/data/datasource/onboarding_remote_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/models/tradition_models.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _logger = AppLogger('TraditionSelectionNotifier');

class TraditionSelectionNotifier extends StateNotifier<TraditionSelectionState> {
  TraditionSelectionNotifier({
    required OnboardingRemoteDatasource remoteDatasource,
    required String language,
  })  : _remoteDatasource = remoteDatasource,
        _language = language,
        super(const TraditionSelectionState()) {
    loadPaths();
  }

  final OnboardingRemoteDatasource _remoteDatasource;
  final String _language;

  Future<void> loadPaths() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final paths = await _remoteDatasource.fetchTraditionOnboardingPaths(
        language: _language,
      );
      state = state.copyWith(paths: paths, isLoading: false);
    } catch (e, stackTrace) {
      _logger.error('Failed to load tradition paths', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load traditions',
      );
    }
  }

  void selectTradition(String code) {
    state = state.copyWith(selectedCode: code, clearError: true);
  }

  Future<bool> submitSelection() async {
    final selectedCode = state.selectedCode;
    if (selectedCode == null || state.isSaving) return false;

    if (selectedCode == traditionShowAllCode) {
      return true;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      await _remoteDatasource.saveUserTradition(
        SaveTraditionRequest(traditionCode: selectedCode),
      );
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e, stackTrace) {
      _logger.error('Failed to save user tradition', e, stackTrace);
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save tradition',
      );
      return false;
    }
  }
}
