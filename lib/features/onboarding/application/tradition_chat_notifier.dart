import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/onboarding/application/tradition_chat_state.dart';
import 'package:flutter_pecha/features/onboarding/data/datasource/onboarding_remote_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/models/tradition_chat_models.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _logger = AppLogger('TraditionChatNotifier');

class TraditionChatNotifier extends StateNotifier<TraditionChatState> {
  TraditionChatNotifier({
    required OnboardingRemoteDatasource remoteDatasource,
    required String language,
  })  : _remoteDatasource = remoteDatasource,
        _language = language,
        super(const TraditionChatState());

  final OnboardingRemoteDatasource _remoteDatasource;
  final String _language;

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    final userMessage = TraditionChatMessage(role: 'user', content: trimmed);
    final updatedMessages = [...state.messages, userMessage];

    state = state.copyWith(
      messages: updatedMessages,
      suggestedTraditions: const [],
      isLoading: true,
      clearError: true,
    );

    try {
      final response = await _remoteDatasource.sendTraditionChatMessage(
        TraditionChatRequest(messages: updatedMessages, language: _language),
      );

      final assistantMessage = TraditionChatMessage(
        role: 'assistant',
        content: response.message,
      );

      state = state.copyWith(
        messages: [...updatedMessages, assistantMessage],
        suggestedTraditions:
            response.isComplete ? const [] : response.suggestedTraditions,
        isComplete: response.isComplete,
        selectedTraditionCode: response.selectedTraditionCode,
        clearSelectedTraditionCode: response.selectedTraditionCode == null,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to send tradition chat message', e, stackTrace);
      state = state.copyWith(
        messages: state.messages.where((m) => m != userMessage).toList(),
        isLoading: false,
        error: 'Failed to send message',
      );
    }
  }

  Future<bool> saveSelectedTradition() async {
    final code = state.selectedTraditionCode;
    if (code == null || state.isSaving) return false;

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      await _remoteDatasource.saveUserTradition(
        SaveTraditionRequest(traditionCode: code),
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
