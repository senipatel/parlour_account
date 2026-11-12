import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:parlour_account/app/theme/app_theme.dart';
import 'package:parlour_account/providers/dashboard_provider.dart';
import 'package:parlour_account/screens/bills/bill_payment_entry_screen.dart';
import 'package:parlour_account/screens/customers/customer_appointment_screen.dart';
import 'package:parlour_account/screens/daily_entry/daily_entry_screen.dart';
import 'package:parlour_account/screens/profile/profile_screen.dart';
import 'package:parlour_account/screens/reports/monthly_analysis_screen.dart';
import 'package:parlour_account/utils/app_navigation.dart';
import 'package:parlour_account/utils/money_amount.dart';

const _entryChartAxisWidth = 40.0;

class EntriesPage extends StatelessWidget {
  const EntriesPage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(appRoute<void>(page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 68,
            titleSpacing: 18,
            title: const _EntriesHeader(),
            actions: [
              IconButton(
                tooltip: 'Profile and settings',
                onPressed: () => _open(context, const ProfilePage()),
                icon: const Icon(Icons.account_circle_outlined),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Consumer<DashboardProvider>(
                    builder: (context, dashboard, _) {
                      final points = dashboard.trend;
                      final income = points.fold<int>(
                          0, (sum, point) => sum + point.income);
                      final expenses = points.fold<int>(
                          0, (sum, point) => sum + point.expenses);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Last 7 days',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                              ),
                              if (dashboard.isLoading)
                                const _StatusPill(
                                    label: 'Updating', active: false)
                              else if (dashboard.error != null)
                                const _StatusPill(
                                    label: 'Offline', active: false)
                              else
                                const _StatusPill(label: 'Live', active: true),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _WeekRange(points: points),
                          const SizedBox(height: 9),
                          _WeekFlowCard(
                            points: points,
                            income: income,
                            expenses: expenses,
                            loading: dashboard.isLoading && points.isEmpty,
                          ),
                          if (dashboard.error != null && points.isEmpty) ...[
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: dashboard.isLoading
                                  ? null
                                  : () => dashboard.load(),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try again'),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Quick actions',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              Text(
                                'Tap to record',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _QuickAction(
                            icon: Icons.add_circle_outline_rounded,
                            color: AppTheme.midnight,
                            title: 'Add daily income or expense',
                            subtitle: 'Record cash and online totals',
                            onTap: () =>
                                _open(context, const DailyDataEntryPage()),
                          ),
                          const SizedBox(height: 7),
                          _QuickAction(
                            icon: Icons.receipt_long_outlined,
                            color: AppTheme.rose,
                            title: 'Add bill or payment',
                            subtitle: 'Log vendor bills and balances due',
                            onTap: () =>
                                _open(context, const BillPaymentEntryPage()),
                          ),
                          const SizedBox(height: 7),
                          // _QuickAction(
                          //   icon: Icons.bar_chart_rounded,
                          //   color: AppTheme.slateBlue,
                          //   title: 'Monthly analysis',
                          //   subtitle: 'Cash flow and monthly breakdown',
                          //   onTap: () =>
                          //       _open(context, const MonthlyAnalysisPage()),
                          // ),
                          // const SizedBox(height: 7),
                          _QuickAction(
                            icon: Icons.people_outline_rounded,
                            color: AppTheme.steel,
                            title: 'Customers & appointments',
                            subtitle: 'Client history and upcoming bookings',
                            onTap: () => _open(
                                context, const CustomerAppointmentPage()),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntriesHeader extends StatelessWidget {
  const _EntriesHeader();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.mist,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.spa_outlined, color: AppTheme.slateBlue),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'OM BEAUTY PARLOUR',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: .7,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text('Entries', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ],
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.slateBlue : AppTheme.steel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(active ? Icons.bolt_rounded : Icons.sync_rounded,
              size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  )),
        ],
      ),
    );
  }
}

class _WeekRange extends StatelessWidget {
  const _WeekRange({required this.points});

  final List<DailyTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Text('Recent income and expenses',
          style: Theme.of(context).textTheme.bodySmall);
    }
    final localizations = MaterialLocalizations.of(context);
    final start = localizations.formatShortDate(points.first.date);
    final end = localizations.formatShortDate(points.last.date);
    return Row(
      children: [
        Icon(Icons.calendar_month_outlined,
            size: 14, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 6),
        Text('$start – $end', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _WeekFlowCard extends StatelessWidget {
  const _WeekFlowCard({
    required this.points,
    required this.income,
    required this.expenses,
    required this.loading,
  });

  final List<DailyTrendPoint> points;
  final int income;
  final int expenses;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final net = income - expenses;
    DailyTrendPoint? peak;
    for (final point in points) {
      if (peak == null || point.income > peak.income) peak = point;
    }
    final peakText = peak == null || peak.income == 0
        ? 'No income recorded this week'
        : 'Highest income day: ${_weekday(peak.date.weekday)} · ${_rupees(peak.income)}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
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
                      Text('NET OPERATING FLOW',
                          style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _rupees(net),
                          style: AppTheme.currencyStat.copyWith(fontSize: 23),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _MiniTotal(label: 'Income', amount: income),
                    const SizedBox(height: 3),
                    _MiniTotal(label: 'Expenses', amount: expenses),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(peakText, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            if (loading)
              const SizedBox(
                height: 136,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (points.isEmpty || (income == 0 && expenses == 0))
              SizedBox(
                height: 136,
                child: Center(
                  child: Text(
                    'Your daily entries will appear here.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              )
            else
              SizedBox(
                height: 136,
                width: double.infinity,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(points
                      .map((point) => '${point.income}:${point.expenses}')
                      .join('|')),
                  tween: Tween(begin: 0, end: 1),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 480),
                  curve: Curves.easeOutCubic,
                  builder: (context, progress, _) => RepaintBoundary(
                    child: CustomPaint(
                      painter: _EntryTrendPainter(points, progress),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Row(
                          children: [
                            const SizedBox(width: _entryChartAxisWidth),
                            Expanded(
                              child: Row(
                                children: [
                                  for (var i = 0; i < points.length; i++)
                                    Expanded(
                                      child: Text(
                                        i == points.length - 1
                                            ? 'Today'
                                            : '${points[i].date.day}/${points[i].date.month}',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(fontSize: 10),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniTotal extends StatelessWidget {
  const _MiniTotal({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(text: '$label  '),
            TextSpan(
              text: _rupees(amount),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      );
}

class _EntryTrendPainter extends CustomPainter {
  const _EntryTrendPainter(this.points, this.progress);

  final List<DailyTrendPoint> points;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const axisWidth = _entryChartAxisWidth;
    const top = 12.0;
    const bottom = 27.0;
    final chartHeight = size.height - top - bottom;
    final plotWidth = size.width - axisWidth;
    final maxValue = points.fold<int>(0, (max, point) {
      final value = point.income > point.expenses ? point.income : point.expenses;
      return value > max ? value : max;
    });
    final grid = Paint()
      ..color = AppTheme.outline
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final fraction = i / 2;
      final y = top + chartHeight * fraction;
      canvas.drawLine(Offset(axisWidth, y), Offset(size.width, y), grid);
      final value = (maxValue * (1 - fraction)).round();
      final label = TextPainter(
        text: TextSpan(
          text: '\u20B9${value ~/ 100}',
          style: const TextStyle(
            color: AppTheme.steel,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: axisWidth - 4);
      label.paint(
        canvas,
        Offset(axisWidth - label.width - 4, y - label.height / 2),
      );
    }
    if (maxValue == 0) return;
    final slot = plotWidth / points.length;
    final barWidth = (slot * .2).clamp(6.0, 17.0);
    final paint = Paint();
    for (var i = 0; i < points.length; i++) {
      final center = axisWidth + slot * (i + .5);
      for (var series = 0; series < 2; series++) {
        final value = series == 0 ? points[i].income : points[i].expenses;
        if (value == 0) continue;
        final height = chartHeight * value / maxValue * progress;
        paint.color = series == 0 ? AppTheme.midnight : AppTheme.rose;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              center + (series == 0 ? -barWidth - 2 : 2),
              top + chartHeight - height,
              barWidth,
              height,
            ),
            const Radius.circular(4),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EntryTrendPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.progress != progress;
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          minVerticalPadding: 6,
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(title, style: Theme.of(context).textTheme.titleSmall),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      );
}

String _rupees(int paise) => '\u20B9${MoneyAmount.formatPaise(paise)}';

String _weekday(int weekday) => const [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ][weekday - 1];
