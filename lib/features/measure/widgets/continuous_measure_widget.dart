import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/measurement.dart';
import '../../../data/models/measurement_method.dart';
import '../../../shared/providers.dart';
import '../services/measurement_engine.dart';
import 'finger_pad_widget.dart';

enum _Phase { idle, running, done }

class ContinuousMeasureWidget extends ConsumerStatefulWidget {
  const ContinuousMeasureWidget({super.key});

  @override
  ConsumerState<ContinuousMeasureWidget> createState() =>
      _ContinuousMeasureWidgetState();
}

class _ContinuousMeasureWidgetState
    extends ConsumerState<ContinuousMeasureWidget> {
  final _engine = MeasurementEngine();
  final _scroll = ScrollController();
  Timer? _ticker;

  _Phase _phase = _Phase.idle;
  final List<double> _values = [];
  final List<DateTime> _times = [];
  bool _saved = false;

  static const double _pointW = 48.0;

  @override
  void dispose() {
    _ticker?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _start() {
    _engine.startScan(1000);
    _values.clear();
    _times.clear();
    setState(() {
      _phase = _Phase.running;
      _saved = false;
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final ua = _engine.sampleNow();
      final now = DateTime.now();
      setState(() {
        _values.add(ua);
        _times.add(now);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients && _scroll.position.maxScrollExtent > 0) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  void _stop() {
    _ticker?.cancel();
    _engine.stopTracking();
    setState(() => _phase = _Phase.done);
  }

  Future<void> _save() async {
    if (_values.isEmpty) return;

    final repo = ref.read(measurementRepoProvider);
    for (int i = 0; i < _values.length; i++) {
      await repo.insert(Measurement(
        measuredAt: _times[i],
        valueUa: _values[i],
        method: MeasurementMethod.touch,
        durationMs: 1000,
      ));
    }

    ref.invalidate(hourlySummariesProvider);
    ref.invalidate(dailySummariesProvider);
    ref.invalidate(monthlySummariesProvider);
    ref.invalidate(measurementsForDateProvider);

    setState(() => _saved = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_values.length}회 측정 기록이 저장되었습니다.',
            style: const TextStyle(fontSize: 16),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 600));
      _reset();
    }
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _phase = _Phase.idle;
      _values.clear();
      _times.clear();
      _saved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildInfoCard(),
          const Spacer(),
          _buildMainContent(),
          const Spacer(),
          _buildBottomArea(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final msg = switch (_phase) {
      _Phase.idle => '시작 버튼을 누르고 손가락을 화면에 올려주세요',
      _Phase.running => '손가락을 유지한 채로 측정 중입니다 — 정지를 눌러 종료하세요',
      _Phase.done => '측정이 완료되었습니다. 저장하거나 다시 측정하세요',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _phase == _Phase.running ? Icons.radio_button_on : Icons.info_outline,
            color: AppTheme.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(fontSize: 15, color: AppTheme.primary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_phase == _Phase.idle) {
      return FingerPadWidget(
        isScanning: false,
        onPointerDownWithRadius: _engine.onPointerDown,
        onPointerMoveWithRadius: _engine.onPointerMove,
        onPointerUp: _engine.onPointerUp,
      );
    }

    if (_phase == _Phase.running) {
      final current = _values.isNotEmpty ? _values.last : null;
      return FingerPadWidget(
        isScanning: true,
        onPointerDownWithRadius: _engine.onPointerDown,
        onPointerMoveWithRadius: _engine.onPointerMove,
        onPointerUp: _engine.onPointerUp,
        overlayText: current != null
            ? '${current.toStringAsFixed(1)} μA\n${_values.length}초'
            : '대기 중...',
      );
    }

    // done
    if (_values.isEmpty) return const SizedBox.shrink();

    final spots = _values
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final avg = _values.reduce((a, b) => a + b) / _values.length;
    final minV = _values.reduce(min);
    final maxV = _values.reduce(max);

    return Column(
      children: [
        _buildChart(spots),
        const SizedBox(height: 12),
        _buildSummary(avg, minV, maxV),
      ],
    );
  }

  Widget _buildChart(List<FlSpot> spots) {
    return LayoutBuilder(builder: (_, constraints) {
      final totalW = max(constraints.maxWidth, spots.length * _pointW);
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: totalW,
              height: 180,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
                child: LineChart(_buildChartData(spots, totalW)),
              ),
            ),
          ),
        ),
      );
    });
  }

  LineChartData _buildChartData(List<FlSpot> spots, double totalW) {
    final maxX = max(spots.length - 1.0, 5.0);
    return LineChartData(
      minX: 0,
      maxX: maxX,
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
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            reservedSize: 40,
            getTitlesWidget: (v, _) => Text('${v.toInt()}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            getTitlesWidget: (v, _) {
              final sec = v.toInt();
              if (sec % 5 != 0) return const SizedBox.shrink();
              return Text('${sec}s',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary));
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
            show: spots.length <= 30,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 3,
              color: AppTheme.primary,
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppTheme.primary.withValues(alpha: 0.08),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touched) => touched.map((s) => LineTooltipItem(
                '${s.x.toInt()}초\n${s.y.toStringAsFixed(1)} μA',
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              )).toList(),
        ),
      ),
    );
  }

  Widget _buildSummary(double avg, double minV, double maxV) {
    return Row(
      children: [
        _StatChip(label: '평균', value: avg),
        const SizedBox(width: 8),
        _StatChip(label: '최소', value: minV),
        const SizedBox(width: 8),
        _StatChip(label: '최대', value: maxV),
      ],
    );
  }

  Widget _buildBottomArea() {
    if (_phase == _Phase.idle) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _start,
          icon: const Icon(Icons.play_arrow_rounded, size: 24),
          label: const Text('측정 시작'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    if (_phase == _Phase.running) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _stop,
          icon: const Icon(Icons.stop_rounded, size: 24),
          label: Text('측정 정지 (${_values.length}초)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    // done
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('다시 측정'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              minimumSize: const Size(0, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saved ? null : _save,
            icon: const Icon(Icons.save_rounded),
            label: Text(_saved ? '저장됨' : '저장'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final double value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
          ],
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(
              '${value.toStringAsFixed(1)} μA',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
