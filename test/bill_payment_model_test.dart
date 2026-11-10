import 'package:flutter_test/flutter_test.dart';
import 'package:parlour_account/models/bill_payment_model.dart';

void main() {
  group('BillPaymentModel', () {
    test('treats existing records without payment fields as paid', () {
      final legacy = {
        'billAmountCash': '12.50',
        'billAmountOnline': '7.50',
      };

      expect(BillPaymentModel.totalPaise(legacy), 2000);
      expect(BillPaymentModel.paidPaise(legacy), 2000);
      expect(BillPaymentModel.outstandingPaise(legacy), 0);
    });

    test('calculates partial payment and outstanding amount in paise', () {
      final partial = {
        'billAmountCash': 5000,
        'billAmountOnline': 2500,
        'paidAmountCash': 1500,
        'paidAmountOnline': 500,
      };

      expect(BillPaymentModel.paidPaise(partial), 2000);
      expect(BillPaymentModel.outstandingPaise(partial), 5500);
      expect(BillPaymentModel.statusFor(7500, 2000), 'partially_paid');
    });

    test('classifies unpaid and fully paid invoices', () {
      expect(BillPaymentModel.statusFor(5000, 0), 'unpaid');
      expect(BillPaymentModel.statusFor(5000, 5000), 'paid');
      expect(BillPaymentModel.statusFor(0, 0), 'paid');
    });
  });
}
