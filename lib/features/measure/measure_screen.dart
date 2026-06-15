import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/measure_mode.dart';
import '../../data/models/measurement.dart';
import '../../data/models/measurement_method.dart';
import '../../core/theme/app_theme.dart';
import '../../features/settings/settings_screen.dart';
import '../../shared/providers.dart';
import 'services/measurement_engine.dart';
import 'widgets/continuous_measure_widget.dart';
import 'widgets/finger_pad_widget.dart';
import 'widgets/scan_animation_widget.dart';
import 'widgets/result_display_widget.dart';

// ── State ───────────────────────────────────────────────────────────────────

enum _ScanState { idle, scanning, result }

class _MeasureState {
  final _ScanState scan;
  final int remaining;
  final double? resultUa;
  final bool saved;

  const _MeasureState({
    this.scan = _ScanState.idle,
    this.remaining = 0,
    this.resultUa,
    this.saved = false,
  });

  _MeasureState copyWith({
    _ScanState? scan,
    int? remaining,
    double? resultUa,
    bool? saved,
  }) =>
      _MeasureState(
        scan: scan ?? this.scan,
        remaining: remaining ?? this.remaining,
        resultUa: resultUa ?? this.resultUa,
        saved: saved ?? this.saved,
      );
}

// ── Screen ───────────────────────────────────────────────────────────────────

class MeasureScreen extends ConsumerStatefulWidget {
  const MeasureScreen({super.key});

  @override
  ConsumerState<MeasureScreen> createState() => _MeasureScreenState();
}

class _MeasureScreenState extends ConsumerState<MeasureScreen> {
  final _engine = MeasurementEngine();
  var _state = const _MeasureState();
  Timer? _scanTimer;
  Timer? _countdownTimer;
  final MeasurementMethod _method = MeasurementMethod.touch;

  int get _scanDurationSec =>
      ref.read(settingsProvider).valueOrNull?.scanDurationSec ?? 3;

  void _startScan() {
    if (_state.scan != _ScanState.idle) return;

    _engine.startScan(_scanDurationSec * 1000);

    setState(() {
      _state = _MeasureState(
        scan: _ScanState.scanning,
        remaining: _scanDurationSec,
      );
    });

    int elapsed = 0;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      elapsed++;
      final remaining = _scanDurationSec - elapsed;
      if (remaining <= 0) {
        t.cancel();
        _finalizeScan();
      } else {
        setState(() {
          _state = _state.copyWith(remaining: remaining);
        });
      }
    });
  }

  void _finalizeScan() {
    final result = _engine.finalize(_method, _scanDurationSec * 1000);
    setState(() {
      _state = _MeasureState(
        scan: _ScanState.result,
        resultUa: result.valueUa,
      );
    });
  }

  Future<void> _saveMeasurement() async {
    final ua = _state.resultUa;
    if (ua == null) return;

    final repo = ref.read(measurementRepoProvider);
    await repo.insert(Measurement(
      measuredAt: DateTime.now(),
      valueUa: ua,
      method: _method,
      durationMs: _scanDurationSec * 1000,
    ));

    ref.invalidate(dailySummariesProvider);
    ref.invalidate(monthlySummariesProvider);
    ref.invalidate(measurementsForDateProvider);

    setState(() {
      _state = _state.copyWith(saved: true);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장되었습니다.', style: TextStyle(fontSize: 16)),
          duration: Duration(seconds: 2),
        ),
      );
      // short delay then reset
      await Future.delayed(const Duration(milliseconds: 600));
      _resetToIdle();
    }
  }

  void _resetToIdle() {
    _scanTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _state = const _MeasureState();
    });
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text(
          '전류 측정',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final settingsAsync = ref.watch(settingsProvider);
    final mode = settingsAsync.valueOrNull?.measureMode ?? MeasureMode.single;

    return Column(
      children: [
        const SizedBox(height: 12),
        _buildModeToggle(mode),
        if (mode == MeasureMode.continuous)
          const Expanded(child: ContinuousMeasureWidget())
        else
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  _buildMainContent(),
                  const SizedBox(height: 24),
                  if (_state.scan == _ScanState.idle) _buildStartButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModeToggle(MeasureMode current) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: MeasureMode.values.map((mode) {
          final selected = current == mode;
          final label = mode == MeasureMode.single ? '단일 측정' : '연속 측정';
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(settingsProvider.notifier).setMeasureMode(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '손가락을 원 위에 올려놓고\n$_scanDurationSec초 동안 유지해주세요',
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.primary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_state.scan) {
      case _ScanState.idle:
        return FingerPadWidget(
          isScanning: false,
          onPointerDownWithRadius: _engine.onPointerDown,
          onPointerMoveWithRadius: _engine.onPointerMove,
          onPointerUp: _engine.onPointerUp,
        );

      case _ScanState.scanning:
        return Listener(
          onPointerDown: (e) => _engine.onPointerDown(e.radiusMajor),
          onPointerMove: (e) => _engine.onPointerMove(e.radiusMajor),
          onPointerUp: (_) => _engine.onPointerUp(),
          child: ScanAnimationWidget(
            isActive: true,
            remainingSeconds: _state.remaining,
          ),
        );

      case _ScanState.result:
        return AnimatedSlide(
          offset: Offset.zero,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          child: ResultDisplayWidget(
            valueUa: _state.resultUa!,
            method: _method,
            onSave: _saveMeasurement,
            onRemeasure: _resetToIdle,
          ),
        );
    }
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _startScan,
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
}
