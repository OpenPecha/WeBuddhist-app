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
    final traditionsToRemove = current
        .where((t) => !selectedCodes.contains(t.traditionCode))
        .toList();

    if (codesToAdd.isEmpty && traditionsToRemove.isEmpty) {
      return true;
    }

    final failedCodes = <String>[];

    for (final tradition in traditionsToRemove) {
      try {
        await _remoteDatasource.deleteUserTradition(tradition.id);
      } catch (e, stackTrace) {
        failedCodes.add(tradition.traditionCode);
        _logger.error(
          'Failed to delete tradition ${tradition.traditionCode}',
          e,
          stackTrace,
        );
      }
    }

    for (final code in codesToAdd) {
      try {
        await _remoteDatasource.saveUserTradition(
          SaveTraditionRequest(traditionCode: code),
        );
      } catch (e, stackTrace) {
        failedCodes.add(code);
        _logger.error('Failed to save tradition $code', e, stackTrace);
      }
    }

    state = await AsyncValue.guard(_remoteDatasource.fetchUserTraditions);

    if (failedCodes.isNotEmpty) {
      _logger.error(
        'Tradition sync partial failure: ${failedCodes.length} operation(s) '
        'failed for codes $failedCodes',
      );
      return false;
    }

    return !state.hasError;
  }
}
