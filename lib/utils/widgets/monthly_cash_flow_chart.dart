import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:parlour_account/app/theme/app_theme.dart';
import 'package:parlour_account/utils/money_amount.dart';

class MonthlyCashFlowChart extends StatelessWidget {
  const MonthlyCashFlowChart({
    required this.incomeCash,
    required this.incomeOnline,
    required this.expenseCash,
    required this.expenseOnline,
    required this.billCash,
    required this.billOnline,
    required this.net,
    super.key,
  });

  final int incomeCash;
  final int incomeOnline;
  final int expenseCash;
  final int expenseOnline;
  final int billCash;
  final int billOnline;
  final int net;

  @override
  Widget build(BuildContext context) {
    final slices = <_FlowSlice>[
      _FlowSlice('Cash income', incomeCash, AppTheme.slateBlue),
      _FlowSlice('Online income', incomeOnline, const Color(0xFF51A58C)),
      _FlowSlice('Cash expenses', expenseCash, AppTheme.rose),
      _FlowSlice('Online expenses', expenseOnline, const Color(0xFFE9A1AF)),
      _FlowSlice('Cash bills', billCash, AppTheme.midnight),
      _FlowSlice('Online bills', billOnline, const Color(0xFF7186B8)),
    ];
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.amount);
    final positive = net >= 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Monthly cash flow',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: (positive
                            ? AppTheme.slateBlue
                            : Theme.of(context).colorScheme.error)
                        .withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    positive ? 'Positive cash flow' : 'Cash deficit',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: positive
                              ? AppTheme.slateBlue
                              : Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text('Income, daily expenses, and bills by payment method',
                style: Theme.of(context).textTheme.bodySmall),
            SizedBox(
              width: double.infinity,
              height: 230,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(210, 210),
                    painter: _FlowDonutPainter(slices, total),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('NET CASH FLOW',
                          style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _rupees(net),
                          style: AppTheme.currencyStat.copyWith(
                            fontSize: 23,
                            color: positive
                                ? AppTheme.slateBlue
                                : Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            for (final slice in slices)
              _FlowLegend(
                slice: slice,
                percent: total == 0 ? 0 : slice.amount / total * 100,
              ),
          ],
        ),
      ),
    );
  }
}

class _FlowSlice {
  const _FlowSlice(this.label, this.amount, this.color);

  final String label;
  final int amount;
  final Color color;
}

class _FlowDonutPainter extends CustomPainter {
  _FlowDonutPainter(this.slices, this.total);

  final List<_FlowSlice> slices;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppTheme.mist
        ..style = PaintingStyle.stroke
        ..strokeWidth = 23,
    );
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (final slice in slices) {
      if (slice.amount <= 0) continue;
      final sweep = 2 * math.pi * slice.amount / total;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = slice.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 23
          ..strokeCap = StrokeCap.round,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _FlowDonutPainter oldDelegate) =>
      oldDelegate.total != total || oldDelegate.slices != slices;
}

class _FlowLegend extends StatelessWidget {
  const _FlowLegend({required this.slice, required this.percent});

  final _FlowSlice slice;
  final double percent;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration:
                  BoxDecoration(color: slice.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 9),
            Expanded(child: Text(slice.label)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: slice.color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${percent.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: slice.color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 10),
            Text(_rupees(slice.amount),
                style: AppTheme.currencyStat.copyWith(fontSize: 15)),
          ],
        ),
      );
}

String _rupees(int paise) => '\u20B9${MoneyAmount.formatPaise(paise)}';
