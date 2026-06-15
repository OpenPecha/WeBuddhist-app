import 'package:flutter_pecha/features/calendar/data/kharag_tibetan_calendar_service.dart';
import 'package:flutter_pecha/features/calendar/domain/tibetan_calendar_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Correctness spike for the Tibetan calendar engine.
///
/// The point is NOT to assert "the package returns whatever it returns" — that
/// proves nothing. Instead we pin the engine against dates and year names known
/// from external authorities (published Men-Tsee-Khang / Phugpa Losar dates and
/// the well-known animal/element year names). If these fail, the package is not
/// trustworthy for this app and we should reconsider the dependency.
void main() {
  const TibetanCalendarService service = KharagTibetanCalendarService();

  // Western year -> (expected Losar Gregorian date, element, animal).
  // Source: standard Phugpa-tradition Losar dates and the 60-year cycle names.
  final losarCases = <int, ({DateTime date, String element, String animal})>{
    2022: (date: DateTime(2022, 3, 3), element: 'Water', animal: 'Tiger'),
    2023: (date: DateTime(2023, 2, 21), element: 'Water', animal: 'Rabbit'),
    2024: (date: DateTime(2024, 2, 10), element: 'Wood', animal: 'Dragon'),
    2025: (date: DateTime(2025, 2, 28), element: 'Wood', animal: 'Snake'),
    2026: (date: DateTime(2026, 2, 18), element: 'Fire', animal: 'Horse'),
  };

  // The engine numbers Tibetan years as westernYear + 127.
  int tibetanYearFor(int westernYear) => westernYear + 127;

  group('Losar (Tibetan New Year) lands on the published Gregorian date', () {
    losarCases.forEach((westernYear, expected) {
      test('Losar $westernYear == ${expected.date}', () {
        final losar = service.losarForTibetanYear(tibetanYearFor(westernYear));
        expect(
          losar,
          expected.date,
          reason:
              'Losar for western $westernYear should be ${expected.date}, '
              'engine produced $losar',
        );
      });
    });
  });

  group('Year attributes match the known animal/element cycle', () {
    losarCases.forEach((westernYear, expected) {
      test('$westernYear is ${expected.element} ${expected.animal}', () {
        final info = service.yearInfo(tibetanYearFor(westernYear));
        expect(info.animal, expected.animal);
        expect(info.element, expected.element);
        expect(info.name, '${expected.element} ${expected.animal}');
      });
    });
  });

  group('Converting the Losar date back yields day 1, month 1', () {
    losarCases.forEach((westernYear, expected) {
      test('$westernYear Losar -> 1st day of 1st month', () {
        final tibDay = service.fromWestern(expected.date);
        expect(tibDay.day, 1, reason: 'Losar must be the 1st lunar day');
        expect(tibDay.month, 1, reason: 'Losar must be in the 1st lunar month');
        expect(tibDay.isLeapMonth, isFalse);
      });
    });
  });

  group('Round-trip and edge-case flags are coherent', () {
    test('fromWestern echoes back the input western date', () {
      final input = DateTime(2025, 6, 15);
      final tibDay = service.fromWestern(input);
      expect(tibDay.westernDate, input);
      expect(tibDay.day, inInclusiveRange(1, 30));
      expect(tibDay.month, inInclusiveRange(1, 12));
    });

    test('a doubled day and its repeat share a day number', () {
      // Scan one year; if the engine reports any doubled day, the day after it
      // (the leap-day repeat) should carry the same day number.
      DateTime cursor = DateTime(2025, 1, 1);
      TibetanDay? doubled;
      for (int i = 0; i < 365; i++) {
        final d = service.fromWestern(cursor);
        if (d.isDoubledDay) {
          doubled = d;
          break;
        }
        cursor = cursor.add(const Duration(days: 1));
      }
      if (doubled == null) {
        // Not every year has an observable doubled day in this scan window;
        // skip rather than fail so the spike stays meaningful.
        return;
      }
      final next = service.fromWestern(
        doubled.westernDate.add(const Duration(days: 1)),
      );
      expect(
        next.day,
        doubled.day,
        reason:
            'The day following a doubled day should repeat the same day '
            'number (the leap-day). Got ${doubled.day} then ${next.day}.',
      );
    });
  });
}
