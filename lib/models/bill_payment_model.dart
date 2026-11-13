import 'package:parlour_account/utils/money_amount.dart';

class BillPaymentModel {
  static int totalPaise(Map<String, dynamic> data) =>
      MoneyAmount.paiseFromStored(data['billTotal']) ??
      (MoneyAmount.paiseFromStored(data['billAmountCash']) ?? 0) +
          (MoneyAmount.paiseFromStored(data['billAmountOnline']) ?? 0);

  static int paidCashPaise(Map<String, dynamic> data) {
    if (!data.containsKey('paidAmountCash') &&
        !data.containsKey('paidAmountOnline')) {
      return MoneyAmount.paiseFromStored(data['billAmountCash']) ?? 0;
    }
    return MoneyAmount.paiseFromStored(data['paidAmountCash']) ?? 0;
  }

  static int paidOnlinePaise(Map<String, dynamic> data) {
    if (!data.containsKey('paidAmountCash') &&
        !data.containsKey('paidAmountOnline')) {
      return MoneyAmount.paiseFromStored(data['billAmountOnline']) ?? 0;
    }
    return MoneyAmount.paiseFromStored(data['paidAmountOnline']) ?? 0;
  }

  static int paidPaise(Map<String, dynamic> data) {
    // Legacy bill entries had no status and represented a completed payment.
    return paidCashPaise(data) + paidOnlinePaise(data);
  }

  static int outstandingPaise(Map<String, dynamic> data) =>
      (totalPaise(data) - paidPaise(data)).clamp(0, 0x7fffffffffffffff).toInt();

  static String statusFor(int total, int paid) {
    if (total <= 0 || paid >= total) return 'paid';
    if (paid <= 0) return 'unpaid';
    return 'partially_paid';
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'partially_paid':
        return 'Part paid';
      default:
        return 'Due';
    }
  }
}
