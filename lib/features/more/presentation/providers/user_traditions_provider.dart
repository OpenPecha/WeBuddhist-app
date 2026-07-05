import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/onboarding/data/datasource/onboarding_remote_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/models/tradition_models.dart';
import 'package:flutter_pecha/features/onboarding/presentation/providers/onboarding_datasource_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('UserTraditionsNotifier');

final userTraditionsProvider =
    AsyncNotifierProvider.autoDispose<UserTraditionsNotifier, List<UserTradition>>(
      UserTraditionsNotifier.new,
    );

class UserTraditionsNotifier extends AutoDisposeAsyncNotifier<List<UserTradition>> {
  late final OnboardingRemoteDatasource _remoteDatasource;

  @override
  Future<List<UserTradition>> build() async {
    _remoteDatasource = ref.watch(onboardingRemoteDatasourceProvider);
    return _remoteDatasource.fetchUserTraditions();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_remoteDatasource.fetchUserTraditions);
  }

  Future<bool> removeTradition(String userTraditionId) async {
    final previous = state.valueOrNull ?? const <UserTradition>[];
    state = AsyncData(
      previous.where((t) => t.id != userTraditionId).toList(),
    );

    try {
      await _remoteDatasource.deleteUserTradition(userTraditionId);
      return true;
    } catch (e, stackTrace) {
      _logger.error('Failed to delete user tradition', e, stackTrace);
      state = AsyncData(previous);
      return false;
    }
  }

  Future<bool> syncSelections(Set<String> selectedCodes) async {
    final current = state.valueOrNull ?? const <UserTradition>[];
    final currentCodes = current.map((t) => t.traditionCode).toSet();
    final codesToAdd = selectedCodes.difference(currentCodes);
    final traditionsToRemove =
        current.where((t) => !selectedCodes.contains(t.traditionCode));

    if (codesToAdd.isEmpty && traditionsToRemove.isEmpty) {
      return true;
    }

    try {
      for (final tradition in traditionsToRemove) {
        await _remoteDatasource.deleteUserTradition(tradition.id);
      }
      for (final code in codesToAdd) {
        await _remoteDatasource.saveUserTradition(
          SaveTraditionRequest(traditionCode: code),
        );
      }
      state = await AsyncValue.guard(_remoteDatasource.fetchUserTraditions);
      return !state.hasError;
    } catch (e, stackTrace) {
      _logger.error('Failed to sync user traditions', e, stackTrace);
      state = await AsyncValue.guard(_remoteDatasource.fetchUserTraditions);
      return false;
    }
  }
}
