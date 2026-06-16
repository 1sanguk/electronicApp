import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/daily_summary.dart';
import 'right_axis_labels.dart';

class HourlyChartWidget extends StatefulWidget {
  final List<DailySummary> summaries;
  const HourlyChartWidget({super.key, required this.summaries});

  @override
  State<HourlyChartWidget> createState() => _HourlyChartWidgetState();
}

class _HourlyChartWidgetState extends State<HourlyChartWidget> {
  final _scroll = ScrollController();
  static const double _pointW = 40.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerCurrentHour());
  }

  void _centerCurrentHour() {
    if (!_scroll.hasClients) return;
    const totalW = 24 * _pointW;
    const leftPad = 20.0;
    const chartAreaW = totalW - leftPad;
    final hour = DateTime.now().hour;
    final xPos = leftPad + (hour / 23.0) * chartAreaW;
    final viewportW = _scroll.position.viewportDimension;
    final target = (xPos - viewportW / 2).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.jumpTo(target);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  int _toHour(String date) {
    // format: "2026-06-13 09:00"
    final parts = date.split(' ');
    if (parts.length < 2) return 0;
    return int.tryParse(parts[1].split(':')[0]) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.summaries.isEmpty) return _empty();

    // Map hour → summary for tooltip lookup
    final byHour = {for (final s in widget.summaries) _toHour(s.date): s};

    final spots = widget.summaries
        .map((s) => FlSpot(_toHour(s.date).toDouble(), s.avgUa))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    return LayoutBuilder(builder: (_, constraints) {
      final totalW = (24 * _pointW)
          .clamp(constraints.maxWidth - RightAxisLabels.width, double.infinity);

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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: LineChart(_buildData(spots, byHour)),
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

  LineChartData _buildData(List<FlSpot> spots, Map<int, DailySummary> byHour) =>
      LineChartData(
        minX: 0,
        maxX: 23,
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
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (v, meta) {
                final h = v.toInt();
                return Text('$h시',
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
              show: true,
              color: AppTheme.primary.withValues(alpha: 0.08),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
              final h = s.x.toInt();
              final summary = byHour[h];
              return LineTooltipItem(
                '$h시\n${summary?.avgUa.toStringAsFixed(1) ?? s.y.toStringAsFixed(1)} μA',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              );
            }).toList(),
          ),
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
        child: const Text('오늘 측정 데이터가 없습니다',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
      );
}
