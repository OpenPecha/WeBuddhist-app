import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_accumulation_selection_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const presetId = 'chenrezig';
  const groupId = 'group-acc-1';

  setUp(() {
    SharedPreferences.setMockInitialValues({
      '${StorageKeys.malaAccumulationSelectionPrefix}$presetId': 'personal',
    });
  });

  ProviderContainer buildContainer() {
    final container = ProviderContainer();
    container.listen(
      malaAccumulationSelectionProvider(presetId),
      (_, __) {},
    );
    return container;
  }

  Future<void> waitForLoad(ProviderContainer container) async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
      final selection = container.read(
        malaAccumulationSelectionProvider(presetId),
      );
      if (!selection.isPersonal || i == 19) return;
    }
  }

  test('applyNavigationIntent before load selects the group accumulation', () async {
    final container = buildContainer();
    addTearDown(container.dispose);

    final notifier =
        container.read(malaAccumulationSelectionProvider(presetId).notifier);
    await notifier.applyNavigationIntent(groupId);
    await waitForLoad(container);

    final selection = container.read(malaAccumulationSelectionProvider(presetId));
    expect(selection.groupAccumulatorId, groupId);
  });

  test('applyNavigationIntent after load overrides persisted personal', () async {
    final container = buildContainer();
    addTearDown(container.dispose);

    final notifier =
        container.read(malaAccumulationSelectionProvider(presetId).notifier);
    await waitForLoad(container);
    await notifier.applyNavigationIntent(groupId);

    final selection = container.read(malaAccumulationSelectionProvider(presetId));
    expect(selection.groupAccumulatorId, groupId);
  });

  test('validateAgainst falls back to personal when group is not joined', () async {
    final container = buildContainer();
    addTearDown(container.dispose);

    final notifier =
        container.read(malaAccumulationSelectionProvider(presetId).notifier);
    await notifier.applyNavigationIntent(groupId);
    await waitForLoad(container);

    await notifier.validateAgainst(const <AccumulatorGroup>[]);

    final selection = container.read(malaAccumulationSelectionProvider(presetId));
    expect(selection.isPersonal, isTrue);
  });
}
