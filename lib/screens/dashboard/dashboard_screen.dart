import 'dart:ui' show FontFeature;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:parlour_account/app/theme/app_theme.dart';
import 'package:parlour_account/providers/dashboard_provider.dart';
import 'package:parlour_account/screens/profile/profile_screen.dart';
import 'package:parlour_account/utils/app_navigation.dart';
import 'package:parlour_account/utils/money_amount.dart';

const _weeklyChartAxisWidth = 40.0;

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

  Future<void> _refresh() => context.read<DashboardProvider>().load();

  void _openProfile() {
    Navigator.of(context).push(appRoute<void>(const ProfilePage()));
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final localizations = MaterialLocalizations.of(context);
    final firstDay = today.subtract(const Duration(days: 6));
    final dateRange = '${localizations.formatShortDate(firstDay)} – '
        '${localizations.formatShortDate(today)}';
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              // toolbarHeight: 68,
              titleSpacing: 18,
              title: const _BrandHeader(),
              actions: [
                _ProfileButton(onPressed: _openProfile),
                const SizedBox(width: 12),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Last 7 days at a glance',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            Consumer<DashboardProvider>(
                              builder: (context, dashboard, _) => _LiveBadge(
                                loading: dashboard.isLoading,
                                error: dashboard.error != null,
                              ),
                            ),
                          ],
                        ),
                        // const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateRange,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Refresh dashboard',
                              visualDensity: VisualDensity.compact,
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Consumer<DashboardProvider>(
                          builder: (context, dashboard, _) {
                            if (dashboard.error != null &&
                                dashboard.trend.isEmpty) {
                              return _DashboardError(
                                message: dashboard.error!,
                                onRetry: dashboard.load,
                              );
                            }
                            if (dashboard.isLoading &&
                                dashboard.trend.isEmpty) {
                              return const _DashboardLoading();
                            }
                            return Column(
                              children: [
                                _MetricGrid(totals: dashboard.totals),
                                const SizedBox(height: 12),
                                _NetCashCard(totals: dashboard.totals),
                                const SizedBox(height: 22),
                                _WeeklyTrendCard(
                                  points: dashboard.trend,
                                  loading: dashboard.isLoading &&
                                      dashboard.trend.isEmpty,
                                ),
                              ],
                            );
                          },
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

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

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
              Text('Overview', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ],
      );
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: IconButton(
        onPressed: onPressed,
        tooltip: 'Profile and settings',
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        icon: CircleAvatar(
          radius: 18,
          backgroundColor: AppTheme.mist,
          foregroundImage: photoUrl == null ? null : NetworkImage(photoUrl),
          child: photoUrl == null
              ? const Icon(Icons.person_outline_rounded,
                  size: 20, color: AppTheme.slateBlue)
              : null,
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.loading, required this.error});

  final bool loading;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error
        ? Theme.of(context).colorScheme.error
        : loading
            ? AppTheme.steel
            : AppTheme.slateBlue;
    final label = error ? 'Offline' : loading ? 'Updating' : 'Live';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.totals});

  final DashboardTotals totals;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 600 ? 4 : 2;
          final gap = 10.0;
          final width =
              (constraints.maxWidth - gap * (columns - 1)) / columns;
          final cards = [
            _MetricCard(
              label: 'INCOME',
              amount: totals.income,
              detail: 'Last 7 days',
              icon: Icons.south_west_rounded,
              color: AppTheme.slateBlue,
            ),
            _MetricCard(
              label: 'EXPENSES',
              amount: totals.expenses,
              detail: 'Last 7 days',
              icon: Icons.north_east_rounded,
              color: AppTheme.rose,
            ),
            _MetricCard(
              label: 'BILLS PAID · 7 DAYS',
              amount: totals.billsPaid,
              detail: 'Last 7 days',
              icon: Icons.receipt_long_outlined,
              color: AppTheme.slateBlue,
            ),
            _MetricCard(
              label: 'DUE / OVERDUE',
              amount: totals.due,
              detail: 'Unpaid balance',
              icon: Icons.account_balance_wallet_outlined,
              color: AppTheme.rose,
            ),
          ];
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final card in cards) SizedBox(width: width, child: card),
            ],
          );
        },
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.amount,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String label;
  final int amount;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
                letterSpacing: .25,
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _rupees(amount),
                style: AppTheme.currencyStat.copyWith(fontSize: 21),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetCashCard extends StatelessWidget {
  const _NetCashCard({required this.totals});

  final DashboardTotals totals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final netColor = totals.net < 0 ? AppTheme.rose : const Color(0xFFA9F1DB);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.midnight,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18121A26),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'NET CASH FLOW · LAST 7 DAYS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFB9C1C8),
                    letterSpacing: .7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    size: 19, color: Color(0xFFA9F1DB)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 260),
            child: Text(
              _rupees(totals.net),
              key: ValueKey(totals.net),
              style: AppTheme.currencyStat.copyWith(
                fontSize: 29,
                color: netColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Divider(color: Color(0x332C3946), height: 1),
          const SizedBox(height: 4),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _CashFlowLine(label: 'Income', amount: totals.income),
              _CashFlowLine(label: 'Expenses', amount: -totals.expenses),
              _CashFlowLine(label: 'Bill payments', amount: -totals.billsPaid),
            ],
          ),
        ],
      ),
    );
  }
}

class _CashFlowLine extends StatelessWidget {
  const _CashFlowLine({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFB9C1C8),
                    )),
            const SizedBox(height: 2),
            Text(
              '${amount < 0 ? '−' : ''}${_rupees(amount.abs())}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ],
        ),
      );
}

class _WeeklyTrendCard extends StatelessWidget {
  const _WeeklyTrendCard({required this.points, required this.loading});

  final List<DailyTrendPoint> points;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final income = points.fold<int>(0, (sum, point) => sum + point.income);
    final expenses = points.fold<int>(0, (sum, point) => sum + point.expenses);
    final hasData = income > 0 || expenses > 0;
    final averageIncome = points.isEmpty ? 0 : (income / points.length).round();
    final net = income - expenses;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text('Last 7 days', style: theme.textTheme.titleMedium),
                      const SizedBox(width: 7),
                      Icon(Icons.trending_up_rounded,
                          size: 18, color: theme.colorScheme.secondary),
                    ],
                  ),
                ),
                const _Legend(color: AppTheme.slateBlue, label: 'Income'),
                const SizedBox(width: 12),
                const _Legend(color: AppTheme.rose, label: 'Exp.'),
              ],
            ),
            const SizedBox(height: 8),
            if (loading)
              const SizedBox(
                height: 142,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!hasData)
              SizedBox(
                height: 142,
                child: Center(
                  child: Text(
                    'Your daily activity will appear here.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              )
            else
              SizedBox(
                height: 142,
                width: double.infinity,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(points
                      .map((point) => '${point.income}:${point.expenses}')
                      .join('|')),
                  tween: Tween(begin: 0, end: 1),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (context, progress, _) => RepaintBoundary(
                    child: CustomPaint(
                      painter: _WeeklyChartPainter(points, progress),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Row(
                          children: [
                            const SizedBox(width: _weeklyChartAxisWidth),
                            Expanded(
                              child: Row(
                                children: [
                                  for (var i = 0; i < points.length; i++)
                                    Expanded(
                                      child: Text(
                                        i == points.length - 1
                                            ? 'Today'
                                            : _weekday(points[i].date.weekday),
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(fontSize: 9),
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TrendSummary(
                  label: 'Avg. daily income',
                  value: _rupees(averageIncome),
                ),
                _TrendSummary(
                  label: 'Income less daily expenses',
                  value: _rupees(net),
                  isNegative: net < 0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChartPainter extends CustomPainter {
  const _WeeklyChartPainter(this.points, this.progress);

  final List<DailyTrendPoint> points;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const axisWidth = _weeklyChartAxisWidth;
    const top = 12.0;
    const bottom = 27.0;
    final chartHeight = size.height - top - bottom;
    final gridPaint = Paint()
      ..color = AppTheme.outline
      ..strokeWidth = 1;
    final plotWidth = size.width - axisWidth;
    final maxValue = points.fold<int>(0, (max, point) {
      final value = point.income > point.expenses ? point.income : point.expenses;
      return value > max ? value : max;
    });
    for (var i = 0; i < 3; i++) {
      final fraction = i / 2;
      final y = top + chartHeight * fraction;
      canvas.drawLine(Offset(axisWidth, y), Offset(size.width, y), gridPaint);
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
    final barWidth = (slot * .2).clamp(5.0, 15.0);
    final barPaint = Paint();
    for (var i = 0; i < points.length; i++) {
      final center = axisWidth + slot * (i + .5);
      final values = [points[i].income, points[i].expenses];
      for (var series = 0; series < values.length; series++) {
        if (values[series] == 0) continue;
        final barHeight = chartHeight * values[series] / maxValue * progress;
        barPaint.color = series == 0 ? AppTheme.slateBlue : AppTheme.rose;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            center + (series == 0 ? -barWidth - 2 : 2),
            top + chartHeight - barHeight,
            barWidth,
            barHeight,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(rect, barPaint);
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
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      );
}

class _TrendSummary extends StatelessWidget {
  const _TrendSummary({
    required this.label,
    required this.value,
    this.isNegative = false,
  });

  final String label;
  final String value;
  final bool isNegative;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.mist,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label  ', style: Theme.of(context).textTheme.bodySmall),
            Text(
              value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isNegative ? Theme.of(context).colorScheme.error : null,
                  ),
            ),
          ],
        ),
      );
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      );
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.cloud_off_outlined, size: 28),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
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
