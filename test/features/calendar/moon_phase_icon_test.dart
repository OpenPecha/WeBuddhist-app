import 'package:flutter/services.dart';
import 'package:flutter_pecha/features/calendar/domain/models/moon_phase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every moon phase has a bundled, declared asset', () async {
    // Theme-neutral: one asset per phase, used in both light and dark mode.
    for (final phase in MoonPhase.values) {
      final path = phase.assetPath();
      final data = await rootBundle.load(path);
      expect(
        data.lengthInBytes,
        greaterThan(0),
        reason: 'expected a bundled asset at $path',
      );
    }
  });
}
