import 'package:flutter_pecha/features/onboarding/data/models/tradition_models.dart';

class TraditionSelectionState {
  const TraditionSelectionState({
    this.paths = const [],
    this.selectedCode,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final List<TraditionPath> paths;
  final String? selectedCode;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  bool get hasSelection => selectedCode != null;

  bool get isShowAllSelected => selectedCode == traditionShowAllCode;

  TraditionSelectionState copyWith({
    List<TraditionPath>? paths,
    String? selectedCode,
    bool clearSelectedCode = false,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return TraditionSelectionState(
      paths: paths ?? this.paths,
      selectedCode:
          clearSelectedCode ? null : (selectedCode ?? this.selectedCode),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
