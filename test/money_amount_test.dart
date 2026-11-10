import 'package:flutter_test/flutter_test.dart';
import 'package:parlour_account/utils/money_amount.dart';

void main() {
  group('MoneyAmount', () {
    test('converts rupees to paise without floating point rounding', () {
      expect(MoneyAmount.rupeesToPaise('12'), 1200);
      expect(MoneyAmount.rupeesToPaise('12.3'), 1230);
      expect(MoneyAmount.rupeesToPaise('12.34'), 1234);
      expect(MoneyAmount.rupeesToPaise('.5'), 50);
      expect(MoneyAmount.rupeesToPaise('1.'), 100);
    });

    test('rejects negative, malformed, over-precision, and overflowing input',
        () {
      expect(MoneyAmount.rupeesToPaise('-1'), isNull);
      expect(MoneyAmount.rupeesToPaise('1.234'), isNull);
      expect(MoneyAmount.rupeesToPaise('abc'), isNull);
      expect(MoneyAmount.rupeesToPaise('92233720368547758.08'), isNull);
    });

    test('reads old rupee strings and new integer-paise values', () {
      expect(MoneyAmount.paiseFromStored('25.5'), 2550);
      expect(MoneyAmount.paiseFromStored(2550), 2550);
      expect(MoneyAmount.formatStored('25.5'), '25.50');
      expect(MoneyAmount.formatStored(2550), '25.50');
    });

    test('validates required values and rejects invalid amounts', () {
      expect(MoneyAmount.validateRupees('', label: 'income'),
          'Please enter income');
      expect(
        MoneyAmount.validateRupees('-4', label: 'income'),
        'Enter a valid non-negative amount with up to 2 decimal places',
      );
      expect(MoneyAmount.validateRupees('0', label: 'income'), isNull);
    });
  });
}
