import 'package:flutter_pecha/core/storage/plan_metadata_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests for the per-day "series handed to OS" marker that deduplicates the
/// catch-up immediate against OS-delivered background notifications.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await PlanMetadataStore.init();
  });

  group('series-scheduled marker', () {
    final today = DateTime(2026, 6, 10);
    final yesterday = DateTime(2026, 6, 9);

    test('absent by default', () {
      expect(PlanMetadataStore.wasSeriesScheduledOn('p-none', today), isFalse);
    });

    test('set → readable for the same date only', () async {
      await PlanMetadataStore.markSeriesScheduledOn('p-1', today, 10005167);
      expect(PlanMetadataStore.wasSeriesScheduledOn('p-1', today), isTrue);
      // Yesterday's stamp never matches today — stale markers read as absent.
      expect(PlanMetadataStore.wasSeriesScheduledOn('p-1', yesterday), isFalse);
    });

    test('clear removes the marker so the catch-up can fire again', () async {
      await PlanMetadataStore.markSeriesScheduledOn('p-2', today, 10005200);
      await PlanMetadataStore.clearSeriesScheduledMarker('p-2');
      expect(PlanMetadataStore.wasSeriesScheduledOn('p-2', today), isFalse);
    });

    test(
      'reverse lookup maps notification IDs to plan IDs for today',
      () async {
        await PlanMetadataStore.markSeriesScheduledOn('p-3', today, 333);
        await PlanMetadataStore.markSeriesScheduledOn('p-4', yesterday, 444);

        final ids = PlanMetadataStore.seriesScheduledIdsOn(today);
        expect(ids[333], 'p-3');
        expect(
          ids.containsKey(444),
          isFalse,
          reason: 'markers stamped on other dates are not today\'s',
        );
      },
    );

    test('clear(planId) also removes the marker', () async {
      await PlanMetadataStore.markSeriesScheduledOn('p-5', today, 555);
      await PlanMetadataStore.clear('p-5');
      expect(PlanMetadataStore.wasSeriesScheduledOn('p-5', today), isFalse);
    });

    test('clearAll wipes markers (logout starts clean)', () async {
      await PlanMetadataStore.markSeriesScheduledOn('p-6', today, 666);
      await PlanMetadataStore.clearAll();
      expect(PlanMetadataStore.wasSeriesScheduledOn('p-6', today), isFalse);
      expect(PlanMetadataStore.seriesScheduledIdsOn(today), isEmpty);
    });
  });
}
