import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Fixed Y-axis scale shown next to a horizontally scrollable chart so the
/// value labels stay visible while the chart content scrolls left/right.
class RightAxisLabels extends StatelessWidget {
  final double minY;
  final double maxY;
  final double interval;
  final double bottomReservedSize;

  const RightAxisLabels({
    super.key,
    required this.minY,
    required this.maxY,
    required this.interval,
    required this.bottomReservedSize,
  });

  static const double width = 56.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 220,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 16, 8),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 1,
            minY: minY,
            maxY: maxY,
            lineBarsData: const [],
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: bottomReservedSize,
                  getTitlesWidget: (_, __) => const SizedBox.shrink(),
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: interval,
                  reservedSize: 40,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
