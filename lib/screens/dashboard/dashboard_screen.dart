import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:parlour_account/app/theme/app_theme.dart';
import 'package:parlour_account/providers/dashboard_provider.dart';
import 'package:parlour_account/screens/bills/bill_payment_entry_screen.dart';
import 'package:parlour_account/screens/customers/customer_appointment_screen.dart';
import 'package:parlour_account/screens/daily_entry/daily_entry_screen.dart';
import 'package:parlour_account/screens/profile/profile_screen.dart';
import 'package:parlour_account/screens/reports/monthly_analysis_screen.dart';
import 'package:parlour_account/utils/money_amount.dart';
import 'package:parlour_account/utils/app_navigation.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DashboardProvider>().load();
    });
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push<void>(appRoute<void>(page));
    if (mounted) await context.read<DashboardProvider>().load();
  }

  Future<void> _refresh() => context.read<DashboardProvider>().load();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('Parlour dashboard'),
              actions: [
                IconButton(
                  tooltip: 'Profile and settings',
                  icon: const Icon(Icons.account_circle_outlined),
                  onPressed: () => _open(const ProfilePage()),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: SliverList.list(children: [
            Text('Today at a glance', style: textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(_todayLabel(), style: textTheme.bodyMedium),
            const SizedBox(height: 18),
            Consumer<DashboardProvider>(
              builder: (context, dashboard, _) {
                if (dashboard.isLoading && dashboard.trend.isEmpty) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (dashboard.error != null && dashboard.trend.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(dashboard.error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: dashboard.load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final totals = dashboard.totals;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: 'Income',
                            amount: totals.income,
                            icon: Icons.south_west_rounded,
                            color: AppTheme.slateBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            label: 'Expenses',
                            amount: totals.expenses,
                            icon: Icons.north_east_rounded,
                            color: AppTheme.graphite,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: 'Bills paid today',
                            amount: totals.billsPaid,
                            icon: Icons.receipt_long_outlined,
                            color: AppTheme.slateBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            label: 'Due / overdue',
                            amount: totals.due,
                            icon: Icons.account_balance_wallet_outlined,
                            color: AppTheme.steel,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SummaryCard(
                      label: 'Net after payments today',
                      amount: totals.net,
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppTheme.midnight,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Text('Last 7 days', style: textTheme.titleLarge)),
                Icon(Icons.insights_rounded,
                    color: Theme.of(context).colorScheme.primary),
              ],
            ),
            const SizedBox(height: 10),
            Consumer<DashboardProvider>(
              builder: (context, dashboard, _) => _WeeklyTrendCard(
                points: dashboard.trend,
                loading: dashboard.isLoading && dashboard.trend.isEmpty,
              ),
            ),
            const SizedBox(height: 24),
            Text('Quick actions', style: textTheme.titleLarge),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth < 440 ? 1 : 2;
              final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(width: width, child: _ActionTile(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Add daily income or expense',
                    onTap: () => _open(const DailyDataEntryPage()),
                  )),
                  SizedBox(width: width, child: _ActionTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Add bill or payment',
                    onTap: () => _open(const BillPaymentEntryPage()),
                  )),
                  SizedBox(width: width, child: _ActionTile(
                    icon: Icons.bar_chart_rounded,
                    title: 'Monthly analysis',
                    onTap: () => _open(const MonthlyAnalysisPage()),
                  )),
                  SizedBox(width: width, child: _ActionTile(
                    icon: Icons.people_outline_rounded,
                    title: 'Customers and appointments',
                    onTap: () => _open(const CustomerAppointmentPage()),
                  )),
                ],
              );
            }),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  String _todayLabel() {
    final date = DateTime.now();
    return '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) => const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ][month - 1];
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final int amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.mist,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(label, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, .12),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Text(
                  '₹${MoneyAmount.formatPaise(amount)}',
                  key: ValueKey(amount),
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyTrendCard extends StatelessWidget {
  const _WeeklyTrendCard({required this.points, required this.loading});

  final List<DailyTrendPoint> points;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Card(
        child: SizedBox(
          height: 210,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (points.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No recent income or expense records yet.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          children: [
            const Row(
              children: [
                _Legend(color: AppTheme.midnight, label: 'Income'),
                SizedBox(width: 18),
                _Legend(color: AppTheme.steel, label: 'Expenses'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 178,
              width: double.infinity,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(points
                    .map((point) => '${point.income}:${point.expenses}')
                    .join('|')),
                tween: Tween(begin: 0, end: 1),
                // duration: const Duration(milliseconds: 700),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) => RepaintBoundary(
                  child: CustomPaint(
                    painter: _WeeklyChartPainter(points, progress),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final point in points)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 148),
                              child: Text(
                                point.shortLabel,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ),
                      ],
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

class _WeeklyChartPainter extends CustomPainter {
  _WeeklyChartPainter(this.points, this.progress);

  final List<DailyTrendPoint> points;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const top = 8.0;
    const bottom = 34.0;
    final chartHeight = size.height - top - bottom;
    final maxValue = points.fold<int>(0, (max, point) {
      final value =
          point.income > point.expenses ? point.income : point.expenses;
      return value > max ? value : max;
    });
    final paint = Paint()..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = top + chartHeight * i / 3;
      paint.color = AppTheme.mist;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final slot = size.width / points.length;
    final barWidth = (slot * .22).clamp(4.0, 14.0);
    for (var i = 0; i < points.length; i++) {
      final center = slot * (i + .5);
      for (var series = 0; series < 2; series++) {
        final value = series == 0 ? points[i].income : points[i].expenses;
        if (maxValue == 0 || value == 0) continue;
        final barHeight = chartHeight * value / maxValue * progress;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            center + (series == 0 ? -barWidth - 2 : 2),
            top + chartHeight - barHeight,
            barWidth,
            barHeight,
          ),
          const Radius.circular(5),
        );
        paint.color = series == 0 ? AppTheme.midnight : AppTheme.steel;
        canvas.drawRRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.progress != progress;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Card(
        child: ListTile(
          minVerticalPadding: 13,
          leading: Icon(icon, color: AppTheme.midnight),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}
