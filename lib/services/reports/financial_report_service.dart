import 'package:parlour_account/services/firebase/account_data.dart';
import 'package:parlour_account/models/financial_report.dart';

class FinancialReportService {
  static const _pageSize = 500;

  Future<FinancialReport> load({
    required String startDate,
    required String endDate,
  }) async {
    final dailyQuery = AccountData.collection('DailyDataEntry')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date', descending: true)
        .limit(_pageSize + 1)
        .get();
    final invoiceQuery = AccountData.collection('BillPaymentEntry')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date', descending: true)
        .limit(_pageSize + 1)
        .get();
    final paymentsQuery = AccountData.collection('BillPaymentEntry')
        .where('paidDate', isGreaterThanOrEqualTo: startDate)
        .where('paidDate', isLessThanOrEqualTo: endDate)
        .orderBy('paidDate', descending: true)
        .limit(_pageSize + 1)
        .get();
    final legacyPaymentQuery = AccountData.collection('BillPaymentEntry')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .limit(_pageSize + 1)
        .get();

    final results = await Future.wait([
      dailyQuery,
      invoiceQuery,
      paymentsQuery,
      legacyPaymentQuery,
    ]);
    final dailySnapshot = results[0];
    final invoiceSnapshot = results[1];
    final paymentsSnapshot = results[2];
    final legacySnapshot = results[3];

    final paymentDocuments = <String, Map<String, dynamic>>{
      for (final doc in paymentsSnapshot.docs.take(_pageSize))
        doc.id: doc.data(),
    };
    for (final doc in legacySnapshot.docs.take(_pageSize)) {
      final data = doc.data();
      if (data['paidDate'] == null) paymentDocuments[doc.id] = data;
    }

    final limited = dailySnapshot.docs.length > _pageSize ||
        invoiceSnapshot.docs.length > _pageSize ||
        paymentsSnapshot.docs.length > _pageSize ||
        legacySnapshot.docs.length > _pageSize;

    return FinancialReport.compute(
      startDate: startDate,
      endDate: endDate,
      dailyRecords: [
        for (final doc in dailySnapshot.docs.take(_pageSize)) doc.data(),
      ],
      invoiceRecords: [
        for (final doc in invoiceSnapshot.docs.take(_pageSize)) doc.data(),
      ],
      paymentRecords: paymentDocuments.values.toList(),
      wasLimited: limited,
    );
  }
}
