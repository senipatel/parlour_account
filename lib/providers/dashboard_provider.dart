import 'package:flutter/foundation.dart';

import 'package:parlour_account/models/bill_payment_model.dart';
import 'package:parlour_account/services/firebase/account_data.dart';
import 'package:parlour_account/utils/money_amount.dart';

class DailyTrendPoint {
  const DailyTrendPoint({
    required this.date,
    required this.income,
    required this.expenses,
  });

  final DateTime date;
  final int income;
  final int expenses;

  String get shortLabel => '${date.day}/${date.month}';
}

class DashboardTotals {
  const DashboardTotals({
    this.income = 0,
    this.expenses = 0,
    this.billsPaid = 0,
    this.due = 0,
  });

  final int income;
  final int expenses;
  final int billsPaid;
  final int due;

  int get net => income - expenses - billsPaid;
}

class DashboardProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  DashboardTotals _totals = const DashboardTotals();
  List<DailyTrendPoint> _trend = const [];

  bool get isLoading => _loading;
  String? get error => _error;
  DashboardTotals get totals => _totals;
  List<DailyTrendPoint> get trend => _trend;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final today = _dateOnly(DateTime.now());
      final firstDay = today.subtract(const Duration(days: 6));
      final todayKey = _dateKey(today);
      final firstKey = _dateKey(firstDay);
      final results = await Future.wait([
        AccountData.collection('DailyDataEntry')
            .where('date', isGreaterThanOrEqualTo: firstKey)
            .where('date', isLessThanOrEqualTo: todayKey)
            .get(),
        AccountData.collection('BillPaymentEntry')
            .where('date', isGreaterThanOrEqualTo: firstKey)
            .where('date', isLessThanOrEqualTo: todayKey)
            .get(),
        AccountData.collection('BillPaymentEntry')
            .where('paidDate', isGreaterThanOrEqualTo: firstKey)
            .where('paidDate', isLessThanOrEqualTo: todayKey)
            .get(),
        AccountData.collection('BillPaymentEntry')
            .where('dueDate', isLessThanOrEqualTo: todayKey)
            .get(),
      ]);

      final trendByDate = <String, List<int>>{};
      for (var i = 0; i < 7; i++) {
        trendByDate[_dateKey(firstDay.add(Duration(days: i)))] = [0, 0];
      }
      var incomeThisWeek = 0;
      var expensesThisWeek = 0;
      for (final doc in results[0].docs) {
        final data = doc.data();
        final income = (MoneyAmount.paiseFromStored(data['incomeCash']) ?? 0) +
            (MoneyAmount.paiseFromStored(data['incomeOnline']) ?? 0);
        final expenses =
            (MoneyAmount.paiseFromStored(data['expenseCash']) ?? 0) +
                (MoneyAmount.paiseFromStored(data['expenseOnline']) ?? 0);
        final dateKey = data['date']?.toString();
        final point = trendByDate[dateKey];
        if (point != null) {
          point[0] += income;
          point[1] += expenses;
        }
        incomeThisWeek += income;
        expensesThisWeek += expenses;
      }

      final paidToday = <String, Map<String, dynamic>>{};
      for (final doc in results[1].docs) {
        final data = doc.data();
        if (data['paidDate'] == null) {
          paidToday[doc.id] = data;
        }
      }
      for (final doc in results[2].docs) {
        paidToday[doc.id] = doc.data();
      }
      var billsPaid = 0;
      for (final data in paidToday.values) {
        billsPaid += BillPaymentModel.paidPaise(data);
      }

      final dueById = <String, Map<String, dynamic>>{
        for (final doc in results[3].docs) doc.id: doc.data(),
      };
      var due = 0;
      for (final data in dueById.values) {
        due += BillPaymentModel.outstandingPaise(data);
      }

      _totals = DashboardTotals(
        income: incomeThisWeek,
        expenses: expensesThisWeek,
        billsPaid: billsPaid,
        due: due,
      );
      _trend = [
        for (var i = 0; i < 7; i++)
          _trendPoint(firstDay.add(Duration(days: i)), trendByDate),
      ];
    } catch (_) {
      _error = 'Could not load dashboard data. Check your connection.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static DailyTrendPoint _trendPoint(
    DateTime date,
    Map<String, List<int>> values,
  ) {
    final totals = values[_dateKey(date)]!;
    return DailyTrendPoint(date: date, income: totals[0], expenses: totals[1]);
  }
}
