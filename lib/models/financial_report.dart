import 'package:parlour_account/models/bill_payment_model.dart';
import 'package:parlour_account/utils/money_amount.dart';

class ReportLine {
  const ReportLine({
    required this.date,
    required this.type,
    required this.category,
    required this.payee,
    required this.description,
    required this.amountPaise,
    this.paidPaise = 0,
    this.outstandingPaise = 0,
    this.status = '',
    this.dueDate = '',
  });

  final String date;
  final String type;
  final String category;
  final String payee;
  final String description;
  final int amountPaise;
  final int paidPaise;
  final int outstandingPaise;
  final String status;
  final String dueDate;
}

class FinancialReport {
  FinancialReport._({
    required this.startDate,
    required this.endDate,
    required this.incomePaise,
    required this.operatingExpensesPaise,
    required this.billInvoicesPaise,
    required this.billPaymentsPaise,
    required this.billOutstandingPaise,
    required this.categoryTotals,
    required this.lines,
    required this.wasLimited,
  });

  factory FinancialReport.compute({
    required String startDate,
    required String endDate,
    required List<Map<String, dynamic>> dailyRecords,
    required List<Map<String, dynamic>> invoiceRecords,
    required List<Map<String, dynamic>> paymentRecords,
    bool wasLimited = false,
  }) {
    var income = 0;
    var operatingExpenses = 0;
    var invoices = 0;
    var payments = 0;
    var outstanding = 0;
    final categories = <String, int>{};
    final lines = <ReportLine>[];

    for (final data in dailyRecords) {
      final entryIncome =
          (MoneyAmount.paiseFromStored(data['incomeCash']) ?? 0) +
              (MoneyAmount.paiseFromStored(data['incomeOnline']) ?? 0);
      final entryExpenses =
          (MoneyAmount.paiseFromStored(data['expenseCash']) ?? 0) +
              (MoneyAmount.paiseFromStored(data['expenseOnline']) ?? 0);
      final date = data['date'] as String? ?? '';
      final description = data['description'] as String? ?? '';
      final incomeCategory =
          data['incomeCategoryName'] as String? ?? 'Uncategorized';
      final expenseCategory =
          data['expenseCategoryName'] as String? ?? 'Uncategorized';
      income += entryIncome;
      operatingExpenses += entryExpenses;
      if (entryIncome > 0) {
        final categoryKey = 'Income / $incomeCategory';
        categories[categoryKey] = (categories[categoryKey] ?? 0) + entryIncome;
        lines.add(ReportLine(
          date: date,
          type: 'Income',
          category: incomeCategory,
          payee: '',
          description: description,
          amountPaise: entryIncome,
        ));
      }
      if (entryExpenses > 0) {
        final categoryKey = 'Expense / $expenseCategory';
        categories[categoryKey] =
            (categories[categoryKey] ?? 0) + entryExpenses;
        lines.add(ReportLine(
          date: date,
          type: 'Expense',
          category: expenseCategory,
          payee: '',
          description: description,
          amountPaise: entryExpenses,
        ));
      }
    }

    for (final data in invoiceRecords) {
      final amount = BillPaymentModel.totalPaise(data);
      final paidForInvoice = BillPaymentModel.paidPaise(data);
      final balance = BillPaymentModel.outstandingPaise(data);
      invoices += amount;
      outstanding += balance;
      lines.add(ReportLine(
        date: data['date'] as String? ?? '',
        type: 'Bill invoice',
        category: data['expenseCategoryName'] as String? ?? 'Uncategorized',
        payee: data['payee'] as String? ?? '',
        description: data['description'] as String? ?? '',
        amountPaise: amount,
        paidPaise: paidForInvoice,
        outstandingPaise: balance,
        status: BillPaymentModel.statusLabel(
          data['paymentStatus'] as String? ?? 'paid',
        ),
        dueDate: data['dueDate'] as String? ?? '',
      ));
    }

    for (final data in paymentRecords) {
      final amount = BillPaymentModel.paidPaise(data);
      payments += amount;
      if (amount > 0) {
        final category =
            data['expenseCategoryName'] as String? ?? 'Uncategorized';
        final categoryKey = 'Bill payment / $category';
        categories[categoryKey] = (categories[categoryKey] ?? 0) + amount;
        lines.add(ReportLine(
          date: data['paidDate'] as String? ?? data['date'] as String? ?? '',
          type: 'Bill payment',
          category: category,
          payee: data['payee'] as String? ?? '',
          description: data['description'] as String? ?? '',
          amountPaise: amount,
          status: BillPaymentModel.statusLabel(
            data['paymentStatus'] as String? ?? 'paid',
          ),
        ));
      }
    }

    lines.sort((a, b) => b.date.compareTo(a.date));
    return FinancialReport._(
      startDate: startDate,
      endDate: endDate,
      incomePaise: income,
      operatingExpensesPaise: operatingExpenses,
      billInvoicesPaise: invoices,
      billPaymentsPaise: payments,
      billOutstandingPaise: outstanding,
      categoryTotals: Map.unmodifiable(categories),
      lines: List.unmodifiable(lines),
      wasLimited: wasLimited,
    );
  }

  final String startDate;
  final String endDate;
  final int incomePaise;
  final int operatingExpensesPaise;
  final int billInvoicesPaise;
  final int billPaymentsPaise;
  final int billOutstandingPaise;
  final Map<String, int> categoryTotals;
  final List<ReportLine> lines;
  final bool wasLimited;

  int get cashNetPaise =>
      incomePaise - operatingExpensesPaise - billPaymentsPaise;
}
