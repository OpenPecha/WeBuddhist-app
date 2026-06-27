import 'package:flutter_pecha/features/onboarding/data/models/tradition_chat_models.dart';

class TraditionChatState {
  const TraditionChatState({
    this.messages = const [],
    this.suggestedTraditions = const [],
    this.isComplete = false,
    this.selectedTraditionCode,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final List<TraditionChatMessage> messages;
  final List<SuggestedTradition> suggestedTraditions;
  final bool isComplete;
  final String? selectedTraditionCode;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  TraditionChatState copyWith({
    List<TraditionChatMessage>? messages,
    List<SuggestedTradition>? suggestedTraditions,
    bool? isComplete,
    String? selectedTraditionCode,
    bool clearSelectedTraditionCode = false,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return TraditionChatState(
      messages: messages ?? this.messages,
      suggestedTraditions: suggestedTraditions ?? this.suggestedTraditions,
      isComplete: isComplete ?? this.isComplete,
      selectedTraditionCode: clearSelectedTraditionCode
          ? null
          : (selectedTraditionCode ?? this.selectedTraditionCode),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
