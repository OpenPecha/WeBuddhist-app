import 'package:flutter_pecha/features/plans/data/utils/plan_date_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlanDateFormat', () {
    test('formatDate uses day, lowercase 3-letter month, and year', () {
      expect(
        PlanDateFormat.formatDate(DateTime(2025, 5, 1)),
        '1 may 2025',
      );
      expect(
        PlanDateFormat.formatDate(DateTime(2025, 12, 2)),
        '2 dec 2025',
      );
      expect(
        PlanDateFormat.formatDate(DateTime(2025, 6, 15)),
        '15 jun 2025',
      );
    });

    test('formatRange joins start and end with a hyphen separator', () {
      expect(
        PlanDateFormat.formatRange(
          DateTime(2025, 5, 1),
          DateTime(2025, 12, 2),
        ),
        '1 may 2025 - 2 dec 2025',
      );
    });

    test('formatRangeOrNull returns null when a bound is missing', () {
      expect(
        PlanDateFormat.formatRangeOrNull(DateTime(2025, 5, 1), null),
        isNull,
      );
      expect(
        PlanDateFormat.formatRangeOrNull(null, DateTime(2025, 12, 2)),
        isNull,
      );
    });

    test('formatRangeOrSingle formats a single date when end is null', () {
      expect(
        PlanDateFormat.formatRangeOrSingle(DateTime(2025, 5, 1), null),
        '1 may 2025',
      );
    });
  });
}
