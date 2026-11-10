import 'dart:convert';
import 'dart:ui' show Rect;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:parlour_account/models/financial_report.dart';
import 'package:parlour_account/utils/money_amount.dart';

class ReportExportService {
  String csv(FinancialReport report) {
    final rows = <List<String>>[
      ['Parlour Account Report', '${report.startDate} to ${report.endDate}'],
      [
        'Limited to first 500 records per query',
        report.wasLimited ? 'Yes' : 'No'
      ],
      ['Income (INR)', MoneyAmount.formatPaise(report.incomePaise)],
      [
        'Operating expenses (INR)',
        MoneyAmount.formatPaise(report.operatingExpensesPaise),
      ],
      [
        'Bill payments (INR)',
        MoneyAmount.formatPaise(report.billPaymentsPaise)
      ],
      ['Cash net (INR)', MoneyAmount.formatPaise(report.cashNetPaise)],
      [
        'Bill invoices issued (INR)',
        MoneyAmount.formatPaise(report.billInvoicesPaise),
      ],
      [
        'Outstanding on bills issued in range (INR)',
        MoneyAmount.formatPaise(report.billOutstandingPaise),
      ],
      [],
      [
        'Date',
        'Type',
        'Category',
        'Payee',
        'Description',
        'Amount (INR)',
        'Paid (INR)',
        'Outstanding (INR)',
        'Status',
        'Due date',
      ],
      for (final line in report.lines)
        [
          line.date,
          line.type,
          line.category,
          line.payee,
          line.description,
          MoneyAmount.formatPaise(line.amountPaise),
          MoneyAmount.formatPaise(line.paidPaise),
          MoneyAmount.formatPaise(line.outstandingPaise),
          line.status,
          line.dueDate,
        ],
    ];
    final content =
        rows.map((row) => row.map(_escapeCsv).join(',')).join('\r\n');
    return '\uFEFF$content';
  }

  Future<Uint8List> pdf(FinancialReport report) async {
    final document = pw.Document();
    final rows = <List<String>>[
      [
        'Date',
        'Type',
        'Category',
        'Payee / description',
        'Amount (INR)',
        'Status',
        'Outstanding (INR)',
      ],
      for (final line in report.lines)
        [
          line.date,
          line.type,
          line.category,
          [line.payee, line.description]
              .where((value) => value.isNotEmpty)
              .join(' - '),
          MoneyAmount.formatPaise(line.amountPaise),
          line.status,
          MoneyAmount.formatPaise(line.outstandingPaise),
        ],
    ];
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (_) => pw.Text(
          'Parlour Account - Financial Report',
          style:
              const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        build: (_) => [
          pw.SizedBox(height: 8),
          pw.Text('Period: ${report.startDate} to ${report.endDate}'),
          if (report.wasLimited)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                'Warning: The report reached the per-query limit of 500 records. Narrow the date range for complete totals.',
              ),
            ),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _summary('Income', report.incomePaise),
              _summary('Daily expenses', report.operatingExpensesPaise),
              _summary('Bill payments', report.billPaymentsPaise),
              _summary('Cash net', report.cashNetPaise),
              _summary('Invoices issued', report.billInvoicesPaise),
              _summary('Outstanding', report.billOutstandingPaise),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Transactions',
            style: const pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          if (report.lines.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Text('No transactions in this date range.'),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: rows.first,
              data: rows.skip(1).toList(),
              headerStyle: const pw.TextStyle(
                  fontSize: 8, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              border: pw.TableBorder.all(color: PdfColors.grey400, width: .4),
            ),
        ],
      ),
    );
    return document.save();
  }

  Future<void> shareCsv(FinancialReport report) async {
    final name = _fileName(report, 'csv');
    final bytes = Uint8List.fromList(utf8.encode(csv(report)));
    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'text/csv', name: name)],
      fileNameOverrides: [name],
      subject: 'Parlour financial report',
      text: 'Financial report ${report.startDate} to ${report.endDate}',
      sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
    );
  }

  Future<void> sharePdf(FinancialReport report) async {
    await Printing.sharePdf(
      bytes: await pdf(report),
      filename: _fileName(report, 'pdf'),
    );
  }

  pw.Widget _summary(String label, int paise) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey500, width: .6),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text('$label: INR ${MoneyAmount.formatPaise(paise)}'),
      );

  String _fileName(FinancialReport report, String extension) =>
      'parlour_report_${report.startDate}_to_${report.endDate}.$extension';

  String _escapeCsv(String value) {
    var safe = value;
    if (RegExp(r'^[=+\-@\t\r]').hasMatch(safe)) safe = "'$safe";
    return '"${safe.replaceAll('"', '""')}"';
  }
}
