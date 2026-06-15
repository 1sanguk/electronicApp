import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/daily_summary.dart';
import 'right_axis_labels.dart';

class WeeklyChartWidget extends StatefulWidget {
  final List<DailySummary> summaries;
  const WeeklyChartWidget({super.key, required this.summaries});

  @override
  State<WeeklyChartWidget> createState() => _WeeklyChartWidgetState();
}

class _WeeklyChartWidgetState extends State<WeeklyChartWidget> {
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

  String _label(String week) => week;

  @override
  Widget build(BuildContext context) {
    if (widget.summaries.isEmpty) return _empty();

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
                    child: BarChart(_buildData()),
                  ),
                ),
              ),
            ),
            const RightAxisLabels(minY: 0, maxY: 100, interval: 20, bottomReservedSize: 28),
          ],
        ),
      );
    });
  }

  BarChartData _buildData() => BarChartData(
        minY: 0,
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
                return Text(_label(widget.summaries[idx].date),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary));
              },
            ),
          ),
        ),
        barGroups: widget.summaries.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.avgUa,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.6),
                    AppTheme.primary,
                  ],
                ),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) {
              final summary = widget.summaries[group.x];
              return BarTooltipItem(
                '${_label(summary.date)}\n${rod.toY.toStringAsFixed(1)} μA',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              );
            },
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
        child: const Text('주간 데이터가 없습니다',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
      );
}
