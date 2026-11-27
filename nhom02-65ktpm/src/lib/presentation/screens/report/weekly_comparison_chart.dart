import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/strings/report_strings.dart';
import '../../../domain/rules/weekly_stats.dart';

/// Biểu đồ cột nhóm: so sánh 4 chỉ số thói quen giữa tuần trước và tuần này.
class WeeklyComparisonChart extends StatelessWidget {
  const WeeklyComparisonChart({super.key, required this.current, required this.previous});

  final WeeklyStats current;
  final WeeklyStats previous;

  static const _labels = [
    ReportStrings.chartSugary,
    ReportStrings.chartFat,
    ReportStrings.chartVeg,
    ReportStrings.chartCarb,
  ];

  List<int> _values(WeeklyStats s) =>
      [s.sugaryDrinks, s.highFatItems, s.mealsWithVeg, s.highCarbMeals];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final prev = _values(previous);
    final cur = _values(current);
    final maxValue = [...prev, ...cur].fold<int>(0, math.max);
    final maxY = math.max(4, maxValue + 1).toDouble();
    final lastWeekColor = scheme.outlineVariant;
    final thisWeekColor = scheme.primary;

    BarChartRodData rod(int value, Color color) => BarChartRodData(
          toY: value.toDouble(),
          color: color,
          width: 14,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        );

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: maxY > 10 ? (maxY / 5).ceilToDouble() : 1,
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => scheme.inverseSurface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                    '${rodIndex == 0 ? ReportStrings.lastWeek : ReportStrings.thisWeek}: '
                    '${rod.toY.toInt()}',
                    TextStyle(color: scheme.onInverseSurface, fontSize: 12),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: maxY > 10 ? (maxY / 5).ceilToDouble() : 1,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text('${value.toInt()}', style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(_labels[value.toInt()], style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < _labels.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [rod(prev[i], lastWeekColor), rod(cur[i], thisWeekColor)],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(color: lastWeekColor, label: ReportStrings.lastWeek),
            const SizedBox(width: 16),
            _Legend(color: thisWeekColor, label: ReportStrings.thisWeek),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
