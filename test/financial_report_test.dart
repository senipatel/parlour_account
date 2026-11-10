import 'package:flutter_test/flutter_test.dart';
import 'package:parlour_account/models/financial_report.dart';
import 'package:parlour_account/services/reports/report_export_service.dart';

void main() {
  group('FinancialReport', () {
    test('reconciles daily totals, bill payments, and invoice balance',
        () async {
      final report = FinancialReport.compute(
        startDate: '2026-03-01',
        endDate: '2026-03-31',
        dailyRecords: [
          {
            'date': '2026-03-10',
            'incomeCash': 10000,
            'incomeOnline': 2500,
            'expenseCash': 1000,
            'expenseOnline': 0,
            'incomeCategoryName': 'Services',
            'expenseCategoryName': 'Supplies',
            'description': 'Daily entries',
          },
        ],
        invoiceRecords: [
          {
            'date': '2026-03-05',
            'billAmountCash': 5000,
            'billAmountOnline': 0,
            'paidAmountCash': 2000,
            'paidAmountOnline': 0,
            'paymentStatus': 'partially_paid',
            'payee': 'Supplier',
            'description': 'Products',
            'expenseCategoryName': 'Supplies',
            'dueDate': '2026-03-20',
          },
        ],
        paymentRecords: [
          {
            'date': '2026-03-05',
            'paidDate': '2026-03-12',
            'billAmountCash': 5000,
            'billAmountOnline': 0,
            'paidAmountCash': 2000,
            'paidAmountOnline': 0,
            'paymentStatus': 'partially_paid',
            'expenseCategoryName': 'Supplies',
          },
        ],
      );

      expect(report.incomePaise, 12500);
      expect(report.operatingExpensesPaise, 1000);
      expect(report.billInvoicesPaise, 5000);
      expect(report.billPaymentsPaise, 2000);
      expect(report.billOutstandingPaise, 3000);
      expect(report.cashNetPaise, 9500);
      expect(report.categoryTotals['Income / Services'], 12500);
      expect(report.categoryTotals['Expense / Supplies'], 1000);
      expect(report.categoryTotals['Bill payment / Supplies'], 2000);
      expect(report.lines.first.date, '2026-03-12');

      final pdfBytes = await ReportExportService().pdf(report);
      expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');
    });

    test('CSV export quotes cells and escapes formula-leading text', () {
      final report = FinancialReport.compute(
        startDate: '2026-03-01',
        endDate: '2026-03-31',
        dailyRecords: [
          {
            'date': '2026-03-10',
            'incomeCash': 0,
            'incomeOnline': 0,
            'expenseCash': 123,
            'expenseOnline': 0,
            'description': '=IMPORTDATA("bad")',
          },
        ],
        invoiceRecords: const [],
        paymentRecords: const [],
      );

      final csv = ReportExportService().csv(report);
      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv, contains("'=IMPORTDATA("));
      expect(csv, contains('""bad""'));
    });
  });
}
