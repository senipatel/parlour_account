import 'package:flutter/material.dart';

import 'package:parlour_account/app/theme/app_theme.dart';
import 'package:parlour_account/models/financial_report.dart';
import 'package:parlour_account/services/reports/financial_report_service.dart';
import 'package:parlour_account/utils/money_amount.dart';
import 'package:parlour_account/services/reports/report_export_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _service = FinancialReportService();
  final _exports = ReportExportService();
  late DateTime _startDate;
  late DateTime _endDate;
  Future<FinancialReport>? _reportFuture;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month, now.day);
    _runReport();
  }

  Future<void> _chooseStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: _endDate,
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _chooseEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  void _runReport() {
    setState(() {
      _reportFuture = _service.load(
        startDate: _dateText(_startDate),
        endDate: _dateText(_endDate),
      );
    });
  }

  Future<void> _export(FinancialReport report, {required bool asPdf}) async {
    setState(() => _exporting = true);
    try {
      if (asPdf) {
        await _exports.sharePdf(report);
      } else {
        await _exports.shareCsv(report);
      }
    } catch (_) {
      _message('Could not prepare or share the report on this device.');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  String _dateText(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Date-range reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _chooseStartDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text('From\n${_dateText(_startDate)}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _chooseEndDate,
                  icon: const Icon(Icons.event),
                  label: Text('Through\n${_dateText(_endDate)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _runReport,
            icon: const Icon(Icons.refresh),
            label: const Text('Run report'),
          ),
          const SizedBox(height: 12),
          FutureBuilder<FinancialReport>(
            future: _reportFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('Could not load this report.'),
                        TextButton(
                          onPressed: _runReport,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final report = snapshot.data;
              if (report == null) return const SizedBox.shrink();
              return _buildReport(report);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReport(FinancialReport report) {
    final categoryRows = report.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${report.startDate} to ${report.endDate}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (report.wasLimited)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'This report reached its per-query limit of 500 records. Narrow the date range for complete totals.',
              ),
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricCard('Income', report.incomePaise, AppTheme.midnight),
            _MetricCard('Daily expenses', report.operatingExpensesPaise,
                AppTheme.slateBlue),
            _MetricCard(
                'Bill payments', report.billPaymentsPaise, AppTheme.steel),
            _MetricCard('Cash net', report.cashNetPaise,
                Theme.of(context).colorScheme.primary),
            _MetricCard('Invoices issued', report.billInvoicesPaise,
                AppTheme.slateBlue),
            _MetricCard('Outstanding on invoices', report.billOutstandingPaise,
                AppTheme.graphite),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    _exporting ? null : () => _export(report, asPdf: false),
                icon: const Icon(Icons.table_view_outlined),
                label: const Text('Share CSV'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    _exporting ? null : () => _export(report, asPdf: true),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Share PDF'),
              ),
            ),
          ],
        ),
        if (_exporting)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Center(child: CircularProgressIndicator()),
          ),
        const SizedBox(height: 24),
        Text('Category breakdown',
            style: Theme.of(context).textTheme.titleLarge),
        if (categoryRows.isEmpty)
          const ListTile(title: Text('No categorized activity in this range.'))
        else
          for (final row in categoryRows)
            ListTile(
              dense: true,
              title: Text(row.key),
              trailing: Text('₹${MoneyAmount.formatPaise(row.value)}'),
            ),
        const SizedBox(height: 12),
        Text('Transactions', style: Theme.of(context).textTheme.titleLarge),
        if (report.lines.isEmpty)
          const ListTile(title: Text('No transactions in this date range.'))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Payee')),
                DataColumn(label: Text('Description')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Paid')),
                DataColumn(label: Text('Outstanding')),
                DataColumn(label: Text('Status')),
              ],
              rows: report.lines
                  .map(
                    (line) => DataRow(cells: [
                      DataCell(Text(line.date)),
                      DataCell(Text(line.type)),
                      DataCell(Text(line.category)),
                      DataCell(Text(line.payee)),
                      DataCell(Text(line.description)),
                      DataCell(Text(
                          '₹${MoneyAmount.formatPaise(line.amountPaise)}')),
                      DataCell(
                          Text('₹${MoneyAmount.formatPaise(line.paidPaise)}')),
                      DataCell(Text(
                          '₹${MoneyAmount.formatPaise(line.outstandingPaise)}')),
                      DataCell(Text(line.status.isEmpty ? '—' : line.status)),
                    ]),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.amountPaise, this.color);

  final String label;
  final int amountPaise;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.circle, size: 12, color: color),
              const SizedBox(height: 6),
              Text(label),
              const SizedBox(height: 4),
              Text(
                '₹${MoneyAmount.formatPaise(amountPaise)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
