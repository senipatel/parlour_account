
import 'package:flutter/material.dart';

import 'package:parlour_account/app/theme/app_theme.dart';
import 'package:parlour_account/models/financial_report.dart';
import 'package:parlour_account/services/reports/financial_report_service.dart';
import 'package:parlour_account/utils/money_amount.dart';
import 'package:parlour_account/services/reports/report_export_service.dart';
import 'package:parlour_account/utils/widgets/monthly_cash_flow_chart.dart';

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
    if (picked != null) {
      setState(() => _startDate = picked);
      _runReport();
    }
  }

  Future<void> _chooseEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      _runReport();
    }
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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 18,
          centerTitle: false,
          title: Column(
            children: [
              Text('Monthly cash flow',
                  style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                // Text('Monthly cash flow',
                //     style: Theme.of(context).textTheme.headlineSmall),
                // const SizedBox(height: 4),
                // Text('Choose a date range to update the report.',
                //     style: Theme.of(context).textTheme.bodyMedium),
                // const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _chooseStartDate,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          'From\n${_dateText(_startDate)}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _chooseEndDate,
                        icon: const Icon(Icons.event),
                        label: Text(
                          'To\n${_dateText(_endDate)}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                  ],
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
          ),
        ),
      ),
    );
  }

  Widget _buildReport(FinancialReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (report.wasLimited) ...[
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'This report reached its per-query limit of 500 records. Narrow the date range for complete totals.',
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        _CashFlowCard(report: report),
        const SizedBox(height: 12),
        _ReportMetricGrid(report: report),
        const SizedBox(height: 14),
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
        const SizedBox(height: 12),
        _ReportRecordSection(
          title: 'Daily entries',
          icon: Icons.receipt_long_outlined,
          records: [
            for (final line in report.lines)
              if (line.type == 'Income' || line.type == 'Expense') line,
          ],
        ),
        const SizedBox(height: 10),
        _ReportRecordSection(
          title: 'Bills and payments',
          icon: Icons.payments_outlined,
          records: [
            for (final line in report.lines)
              if (line.type == 'Bill invoice' || line.type == 'Bill payment')
                line,
          ],
        ),
      ],
    );
  }
}

class _ReportRecordSection extends StatelessWidget {
  const _ReportRecordSection({
    required this.title,
    required this.icon,
    required this.records,
  });

  final String title;
  final IconData icon;
  final List<ReportLine> records;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
          title: Text(title),
          subtitle: Text('${records.length} record(s)'),
          children: [
            if (records.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('No records in this date range.'),
                ),
              )
            else
              for (var i = 0; i < records.length; i++) ...[
                _ReportRecordTile(line: records[i]),
                if (i < records.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
          ],
        ),
      );
}

class _ReportRecordTile extends StatelessWidget {
  const _ReportRecordTile({required this.line});

  final ReportLine line;

  @override
  Widget build(BuildContext context) {
    final isInvoice = line.type == 'Bill invoice';
    final detail = line.payee.isNotEmpty ? line.payee : line.category;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${line.type}  ·  ${line.date}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 112),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _rupees(line.amountPaise),
                    style: AppTheme.currencyStat.copyWith(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          if (line.description.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              line.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (line.status.isNotEmpty || line.dueDate.isNotEmpty) ...[
            const SizedBox(height: 7),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (line.status.isNotEmpty)
                  _RecordTag(label: line.status, color: AppTheme.slateBlue),
                if (isInvoice && line.paidPaise > 0)
                  _RecordTag(
                    label: 'Paid ${_rupees(line.paidPaise)}',
                    color: AppTheme.midnight,
                  ),
                if (isInvoice && line.outstandingPaise > 0)
                  _RecordTag(
                    label: 'Due ${_rupees(line.outstandingPaise)}',
                    color: AppTheme.rose,
                  ),
                if (line.dueDate.isNotEmpty)
                  _RecordTag(
                    label: 'Due date ${line.dueDate}',
                    color: AppTheme.rose,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordTag extends StatelessWidget {
  const _RecordTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      );
}

class _CashFlowCard extends StatelessWidget {
  const _CashFlowCard({required this.report});

  final FinancialReport report;

  @override
  Widget build(BuildContext context) => MonthlyCashFlowChart(
        incomeCash: report.incomeCashPaise,
        incomeOnline: report.incomeOnlinePaise,
        expenseCash: report.expenseCashPaise,
        expenseOnline: report.expenseOnlinePaise,
        billCash: report.billCashPaise,
        billOnline: report.billOnlinePaise,
        net: report.cashNetPaise,
      );
}
class _ReportMetricGrid extends StatelessWidget {
  const _ReportMetricGrid({required this.report});

  final FinancialReport report;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          const gap = 10.0;
          final width = (constraints.maxWidth - gap) / 2;
          final metrics = [
            _ReportMetric('Total income', report.incomePaise,
                Icons.south_west_rounded, AppTheme.slateBlue),
            _ReportMetric('Daily expenses', report.operatingExpensesPaise,
                Icons.north_east_rounded, AppTheme.rose),
            _ReportMetric('Bills settled', report.billPaymentsPaise,
                Icons.receipt_long_outlined, AppTheme.midnight),
            _ReportMetric('Vendor dues', report.billOutstandingPaise,
                Icons.account_balance_wallet_outlined, AppTheme.rose),
          ];
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final metric in metrics)
                SizedBox(width: width, child: metric),
            ],
          );
        },
      );
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric(this.label, this.amount, this.icon, this.color);

  final String label;
  final int amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(_rupees(amount),
                    style: AppTheme.currencyStat.copyWith(fontSize: 19)),
              ),
            ],
          ),
        ),
      );
}

String _rupees(int paise) => '\u20B9${MoneyAmount.formatPaise(paise)}';
