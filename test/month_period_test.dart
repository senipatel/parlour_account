import 'package:flutter_test/flutter_test.dart';
import 'package:parlour_account/utils/month_period.dart';

void main() {
  group('MonthPeriod', () {
    test('uses the next calendar year as the exclusive December boundary', () {
      final period = MonthPeriod.fromDateString('2025-12-14')!;

      expect(period.key, '2025-12');
      expect(period.label, 'December 2025');
      expect(period.startDate, '2025-12-01');
      expect(period.endDateExclusive, '2026-01-01');
    });

    test('calculates the exclusive boundary for other months', () {
      final period = MonthPeriod.fromDateString('2024-02-29')!;

      expect(period.startDate, '2024-02-01');
      expect(period.endDateExclusive, '2024-03-01');
    });

    test('ignores invalid dates and returns unique newest-first periods', () {
      final periods = MonthPeriod.fromDateStrings([
        '2024-01-02',
        '2025-03-01',
        '2024-01-31',
        '2025-13-01',
        'No date selected',
        null,
        '2025-02-30',
      ]);

      expect(periods.map((period) => period.key).toList(), [
        '2025-03',
        '2024-01',
      ]);
    });
  });
}
