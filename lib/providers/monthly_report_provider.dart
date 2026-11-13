import 'package:flutter/foundation.dart';

import 'package:parlour_account/models/bill_payment_model.dart';
import 'package:parlour_account/services/firebase/account_data.dart';
import 'package:parlour_account/utils/month_period.dart';
import 'package:parlour_account/utils/money_amount.dart';

class MonthlyReportData {
  const MonthlyReportData({
    required this.dailyEntries,
    required this.billEntries,
    required this.incomeCash,
    required this.incomeOnline,
    required this.expenseCash,
    required this.expenseOnline,
    required this.billPaidCash,
    required this.billPaidOnline,
    required this.billPaid,
    required this.billOutstanding,
  });

  final List<Map<String, dynamic>> dailyEntries;
  final List<Map<String, dynamic>> billEntries;
  final int incomeCash;
  final int incomeOnline;
  final int expenseCash;
  final int expenseOnline;
  final int billPaidCash;
  final int billPaidOnline;
  final int billPaid;
  final int billOutstanding;

  int get income => incomeCash + incomeOnline;
  int get dailyExpenses => expenseCash + expenseOnline;
  int get net => income - dailyExpenses - billPaid;
}

class MonthlyReportProvider extends ChangeNotifier {
  List<MonthPeriod> _periods = const [];
  String? _selectedPeriodKey;
  MonthlyReportData? _report;
  bool _loadingPeriods = false;
  bool _loadingReport = false;
  String? _error;

  List<MonthPeriod> get periods => _periods;
  String? get selectedPeriodKey => _selectedPeriodKey;
  MonthlyReportData? get report => _report;
  bool get isLoadingPeriods => _loadingPeriods;
  bool get isLoadingReport => _loadingReport;
  String? get error => _error;

  void selectPeriod(String? key) {
    if (_selectedPeriodKey != key) {
      _report = null;
    }
    _selectedPeriodKey = key;
    notifyListeners();
  }

  Future<void> loadPeriods() async {
    _loadingPeriods = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        AccountData.collection('DailyDataEntry').get(),
        AccountData.collection('BillPaymentEntry').get(),
      ]);
      final periods = MonthPeriod.fromDateStrings([
        for (final doc in results[0].docs) doc.data()['date']?.toString(),
        for (final doc in results[1].docs) doc.data()['date']?.toString(),
      ]);
      _periods = periods;
      if (!_periods.any((period) => period.key == _selectedPeriodKey)) {
        _selectedPeriodKey = periods.isEmpty ? null : periods.first.key;
        _report = null;
      }
    } catch (_) {
      _error = 'Could not load report months. Check your connection.';
    } finally {
      _loadingPeriods = false;
      notifyListeners();
    }
  }

  Future<void> loadReport() async {
    MonthPeriod? period;
    for (final candidate in _periods) {
      if (candidate.key == _selectedPeriodKey) {
        period = candidate;
        break;
      }
    }
    if (period == null) return;
    _loadingReport = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        AccountData.collection('DailyDataEntry')
            .where('date', isGreaterThanOrEqualTo: period.startDate)
            .where('date', isLessThan: period.endDateExclusive)
            .get(),
        AccountData.collection('BillPaymentEntry')
            .where('date', isGreaterThanOrEqualTo: period.startDate)
            .where('date', isLessThan: period.endDateExclusive)
            .get(),
      ]);
      final dailyEntries = [for (final doc in results[0].docs) doc.data()];
      final billEntries = [for (final doc in results[1].docs) doc.data()];
      var incomeCash = 0;
      var incomeOnline = 0;
      var expenseCash = 0;
      var expenseOnline = 0;
      var billPaidCash = 0;
      var billPaidOnline = 0;
      var billPaid = 0;
      var billOutstanding = 0;
      for (final data in dailyEntries) {
        incomeCash += MoneyAmount.paiseFromStored(data['incomeCash']) ?? 0;
        incomeOnline += MoneyAmount.paiseFromStored(data['incomeOnline']) ?? 0;
        expenseCash += MoneyAmount.paiseFromStored(data['expenseCash']) ?? 0;
        expenseOnline +=
            MoneyAmount.paiseFromStored(data['expenseOnline']) ?? 0;
      }
      for (final data in billEntries) {
        billPaidCash += BillPaymentModel.paidCashPaise(data);
        billPaidOnline += BillPaymentModel.paidOnlinePaise(data);
        billPaid += BillPaymentModel.paidPaise(data);
        billOutstanding += BillPaymentModel.outstandingPaise(data);
      }
      _report = MonthlyReportData(
        dailyEntries: dailyEntries,
        billEntries: billEntries,
        incomeCash: incomeCash,
        incomeOnline: incomeOnline,
        expenseCash: expenseCash,
        expenseOnline: expenseOnline,
        billPaidCash: billPaidCash,
        billPaidOnline: billPaidOnline,
        billPaid: billPaid,
        billOutstanding: billOutstanding,
      );
    } catch (_) {
      _error = 'Could not load this month’s report. Try again.';
    } finally {
      _loadingReport = false;
      notifyListeners();
    }
  }
}
