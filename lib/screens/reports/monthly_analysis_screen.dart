import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:parlour_account/app/theme/app_theme.dart';
import 'package:parlour_account/models/bill_payment_model.dart';
import 'package:parlour_account/providers/monthly_report_provider.dart';
import 'package:parlour_account/utils/money_amount.dart';

class MonthlyAnalysisPage extends StatefulWidget {
  const MonthlyAnalysisPage({super.key});

  @override
  State<MonthlyAnalysisPage> createState() => _MonthlyAnalysisPageState();
}

class _MonthlyAnalysisPageState extends State<MonthlyAnalysisPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<MonthlyReportProvider>();
      await provider.loadPeriods();
      if (mounted && provider.selectedPeriodKey != null) {
        await provider.loadReport();
      }
    });
  }

  Future<void> _refresh() async {
    final provider = context.read<MonthlyReportProvider>();
    await provider.loadPeriods();
    if (mounted && provider.selectedPeriodKey != null) {
      await provider.loadReport();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Monthly report'),
          actions: [
            IconButton(
              tooltip: 'Refresh report',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Consumer<MonthlyReportProvider>(
          builder: (context, provider, _) {
            if (provider.isLoadingPeriods && provider.periods.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.error != null && provider.periods.isEmpty) {
              return _MessageState(
                icon: Icons.cloud_off_outlined,
                message: provider.error!,
                actionLabel: 'Try again',
                onAction: provider.loadPeriods,
              );
            }
            if (provider.periods.isEmpty) {
              return const _MessageState(
                icon: Icons.insert_chart_outlined_rounded,
                message:
                    'No monthly records yet. Add an entry to see a report.',
              );
            }
            final report = provider.report;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Text('Your month, clearly summarized',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 5),
                Text('Review cash flow and payments in one place.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(provider.selectedPeriodKey),
                            initialValue: provider.selectedPeriodKey,
                            decoration: const InputDecoration(
                              labelText: 'Report month',
                              prefixIcon: Icon(Icons.calendar_month_outlined),
                            ),
                            items: [
                              for (final period in provider.periods)
                                DropdownMenuItem(
                                  value: period.key,
                                  child: Text(period.label),
                                ),
                            ],
                            onChanged: (value) async {
                              provider.selectPeriod(value);
                              await provider.loadReport();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filled(
                          tooltip: 'Load selected month',
                          onPressed: provider.isLoadingReport
                              ? null
                              : provider.loadReport,
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
                if (provider.isLoadingReport)
                  const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: LinearProgressIndicator(),
                  ),
                if (provider.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _InlineError(message: provider.error!),
                  ),
                if (report != null) ...[
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    child: _MonthlyDonutCard(
                      key: ValueKey(
                        '${provider.selectedPeriodKey}:'
                        '${report.income}:${report.dailyExpenses}:${report.billPaid}',
                      ),
                      report: report,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TotalsGrid(report: report),
                  const SizedBox(height: 20),
                  _DailyRecords(entries: report.dailyEntries),
                  const SizedBox(height: 12),
                  _BillRecords(entries: report.billEntries),
                ] else if (!provider.isLoadingReport && provider.error == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 36),
                    child: _MessageState(
                      icon: Icons.bar_chart_rounded,
                      message: 'Choose a month to load its report.',
                    ),
                  ),
              ],
            );
          },
        ),
      );
}

class _MonthlyDonutCard extends StatelessWidget {
  const _MonthlyDonutCard({required this.report, super.key});

  final MonthlyReportData report;

  @override
  Widget build(BuildContext context) {
    final slices = <_Slice>[
      _Slice('Income', report.income, AppTheme.midnight),
      _Slice('Daily expenses', report.dailyExpenses, AppTheme.slateBlue),
      _Slice('Bill payments', report.billPaid, AppTheme.steel),
    ];
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.value);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cash flow', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Income, daily expenses, and bills paid',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            SizedBox(
              height: 222,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) => Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(206, 206),
                      painter: _DonutPainter(slices, total, progress),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('NET CASH',
                            style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: 4),
                        FittedBox(
                          child: Text(
                            '₹${MoneyAmount.formatPaise(report.net)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            for (final slice in slices)
              _SliceLegend(
                slice: slice,
                percent: total == 0 ? 0 : slice.value / total * 100,
              ),
          ],
        ),
      ),
    );
  }
}

class _Slice {
  const _Slice(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices, this.total, this.progress);

  final List<_Slice> slices;
  final int total;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 7;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = AppTheme.mist
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25;
    canvas.drawCircle(center, radius, track);
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (final slice in slices) {
      if (slice.value <= 0) continue;
      final sweep = 2 * math.pi * slice.value / total * progress;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 25
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += 2 * math.pi * slice.value / total * progress;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.total != total || oldDelegate.progress != progress;
}

class _SliceLegend extends StatelessWidget {
  const _SliceLegend({required this.slice, required this.percent});

  final _Slice slice;
  final double percent;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: slice.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 9),
            Expanded(child: Text(slice.label)),
            Text('${percent.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 12),
            Text('₹${MoneyAmount.formatPaise(slice.value)}',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
}

class _TotalsGrid extends StatelessWidget {
  const _TotalsGrid({required this.report});

  final MonthlyReportData report;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _MetricCard(
                      'Income', report.income, Icons.south_west_rounded)),
              const SizedBox(width: 12),
              Expanded(
                  child: _MetricCard('Daily expenses', report.dailyExpenses,
                      Icons.north_east_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _MetricCard('Bills paid', report.billPaid,
                      Icons.receipt_long_outlined)),
              const SizedBox(width: 12),
              Expanded(
                  child: _MetricCard('Outstanding', report.billOutstanding,
                      Icons.account_balance_wallet_outlined)),
            ],
          ),
        ],
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.amount, this.icon);

  final String label;
  final int amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.slateBlue),
              const SizedBox(height: 10),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('₹${MoneyAmount.formatPaise(amount)}',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
        ),
      );
}

class _DailyRecords extends StatelessWidget {
  const _DailyRecords({required this.entries});

  final List<Map<String, dynamic>> entries;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: const Text('Daily entries'),
          subtitle: Text('${entries.length} record(s)'),
          children: [
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text('No daily entries for this month.'),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Income · cash')),
                    DataColumn(label: Text('Income · online')),
                    DataColumn(label: Text('Expense · cash')),
                    DataColumn(label: Text('Expense · online')),
                    DataColumn(label: Text('Note')),
                  ],
                  rows: [
                    for (final data in entries)
                      DataRow(cells: [
                        DataCell(Text(data['date']?.toString() ?? '—')),
                        DataCell(
                            Text(MoneyAmount.formatStored(data['incomeCash']))),
                        DataCell(Text(
                            MoneyAmount.formatStored(data['incomeOnline']))),
                        DataCell(Text(
                            MoneyAmount.formatStored(data['expenseCash']))),
                        DataCell(Text(
                            MoneyAmount.formatStored(data['expenseOnline']))),
                        DataCell(Text(data['description']?.toString() ?? '')),
                      ]),
                  ],
                ),
              ),
          ],
        ),
      );
}

class _BillRecords extends StatelessWidget {
  const _BillRecords({required this.entries});

  final List<Map<String, dynamic>> entries;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: const Icon(Icons.payments_outlined),
          title: const Text('Bills and payments'),
          subtitle: Text('${entries.length} record(s)'),
          children: [
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text('No bill records for this month.'),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Payee')),
                    DataColumn(label: Text('Bill amount')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Outstanding')),
                    DataColumn(label: Text('Due date')),
                  ],
                  rows: [
                    for (final data in entries)
                      DataRow(cells: [
                        DataCell(Text(data['date']?.toString() ?? '—')),
                        DataCell(Text(data['payee']?.toString() ?? '—')),
                        DataCell(Text('₹${MoneyAmount.formatPaise(
                          (MoneyAmount.paiseFromStored(
                                      data['billAmountCash']) ??
                                  0) +
                              (MoneyAmount.paiseFromStored(
                                      data['billAmountOnline']) ??
                                  0),
                        )}')),
                        DataCell(Text(BillPaymentModel.statusLabel(
                            data['paymentStatus'] as String? ?? 'paid'))),
                        DataCell(Text('₹${MoneyAmount.formatPaise(
                          BillPaymentModel.outstandingPaise(data),
                        )}')),
                        DataCell(Text(data['dueDate']?.toString() ?? '—')),
                      ]),
                  ],
                ),
              ),
          ],
        ),
      );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
        color: AppTheme.steel,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            const Icon(Icons.error_outline, color: AppTheme.graphite),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ]),
        ),
      );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: AppTheme.steel),
              const SizedBox(height: 14),
              Text(message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 12),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      );
}
