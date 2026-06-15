import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/daily_summary.dart';
import 'right_axis_labels.dart';

class DailyChartWidget extends StatefulWidget {
  final List<DailySummary> summaries;
  final void Function(String date)? onTap;

  const DailyChartWidget({super.key, required this.summaries, this.onTap});

  @override
  State<DailyChartWidget> createState() => _DailyChartWidgetState();
}

class _DailyChartWidgetState extends State<DailyChartWidget> {
  final _scroll = ScrollController();
  static const double _pointW = 72.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients && _scroll.position.maxScrollExtent > 0) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.summaries.isEmpty) return _empty();

    final spots = widget.summaries.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.avgUa))
        .toList();

    return LayoutBuilder(builder: (_, constraints) {
      final totalW = max(constraints.maxWidth - RightAxisLabels.width,
          widget.summaries.length * _pointW);

      return _chartShell(
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: totalW,
                  height: 220,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 0, 8),
                    child: LineChart(_buildData(spots)),
                  ),
                ),
              ),
            ),
            const RightAxisLabels(minY: 20, maxY: 100, interval: 20, bottomReservedSize: 28),
          ],
        ),
      );
    });
  }

  LineChartData _buildData(List<FlSpot> spots) => LineChartData(
        minY: 20,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Color(0xFFEEEEEE), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= widget.summaries.length) return const SizedBox.shrink();
                final date = DateTime.parse(widget.summaries[idx].date);
                return Text(DateFormat('M/d').format(date),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary));
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4, color: AppTheme.primary, strokeWidth: 2, strokeColor: Colors.white),
            ),
            belowBarData: BarAreaData(
                show: true, color: AppTheme.primary.withValues(alpha: 0.08)),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final summary = widget.summaries[s.spotIndex];
              return LineTooltipItem(
                '${summary.date}\n${summary.avgUa.toStringAsFixed(1)} μA',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              );
            }).toList(),
          ),
          touchCallback: (event, response) {
            if (event is FlTapUpEvent && response?.lineBarSpots != null) {
              final idx = response!.lineBarSpots!.first.spotIndex;
              if (idx < widget.summaries.length) {
                widget.onTap?.call(widget.summaries[idx].date);
              }
            }
          },
        ),
      );

  Widget _chartShell(Widget child) => Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
      );

  Widget _empty() => Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: AppTheme.textSecondary),
            SizedBox(height: 8),
            Text('측정 데이터가 없습니다',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
          ],
        ),
      );
}
