import 'package:flutter_pecha/features/onboarding/application/tradition_chat_notifier.dart';
import 'package:flutter_pecha/features/onboarding/application/tradition_chat_state.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_provider.dart';
import 'package:flutter_pecha/features/onboarding/presentation/providers/onboarding_datasource_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final traditionChatProvider =
    StateNotifierProvider.autoDispose<TraditionChatNotifier, TraditionChatState>(
  (ref) {
    final language = ref.watch(
      onboardingProvider.select((state) => state.preferences.primaryLanguage),
    );
    return TraditionChatNotifier(
      remoteDatasource: ref.watch(onboardingRemoteDatasourceProvider),
      language: language,
    );
  },
);
