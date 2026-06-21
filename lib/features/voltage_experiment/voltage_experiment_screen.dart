import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'services/battery_voltage_service.dart';

/// 손가락이 폰에 닿았을 때 배터리 전압(mV)이 변하는지 직접 확인해보는 실험 화면.
/// 기준값(접촉 없음) 측정 후, 그 시점 이후의 모든 값을 기준값과의 차이(mV)로 표시한다.
class VoltageExperimentScreen extends StatefulWidget {
  const VoltageExperimentScreen({super.key});

  @override
  State<VoltageExperimentScreen> createState() => _VoltageExperimentScreenState();
}

class _VoltageExperimentScreenState extends State<VoltageExperimentScreen> {
  int? _baselineMv;
  int? _currentMv;
  bool _running = false;
  bool _unsupported = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _captureBaseline() async {
    final mv = await BatteryVoltageService.readVoltageMv();
    if (mv == null) {
      setState(() => _unsupported = true);
      return;
    }
    setState(() {
      _baselineMv = mv;
      _currentMv = mv;
      _unsupported = false;
    });
  }

  void _startSampling() {
    if (_baselineMv == null) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final mv = await BatteryVoltageService.readVoltageMv();
      if (mv != null && mounted) {
        setState(() => _currentMv = mv);
      }
    });
  }

  void _stopSampling() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _baselineMv = null;
      _currentMv = null;
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final diff = (_baselineMv != null && _currentMv != null) ? _currentMv! - _baselineMv! : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text(
          '실험: 배터리 전압',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '손가락을 대지 않은 상태에서 기준값을 측정한 뒤, 화면이나 측면을 손가락으로 잡고 전압이 변하는지 확인해보세요.',
              style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            if (_unsupported)
              const Text(
                '이 기기에서는 배터리 전압을 읽을 수 없습니다 (iOS 또는 미지원 기기).',
                style: TextStyle(fontSize: 15, color: AppTheme.error),
              ),
            _InfoRow(label: '기준값', value: _baselineMv == null ? '-' : '$_baselineMv mV'),
            const SizedBox(height: 8),
            _InfoRow(label: '현재값', value: _currentMv == null ? '-' : '$_currentMv mV'),
            const SizedBox(height: 8),
            _InfoRow(
              label: '차이',
              value: diff == null ? '-' : '${diff >= 0 ? '+' : ''}$diff mV',
              valueColor: diff == null || diff == 0
                  ? AppTheme.textPrimary
                  : (diff > 0 ? AppTheme.primary : AppTheme.error),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _running ? null : _captureBaseline,
              child: const Text('기준값 측정 (손 떼고)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _baselineMv == null ? null : (_running ? _stopSampling : _startSampling),
              child: Text(_running ? '측정 중지' : '손가락 대고 측정 시작'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
              child: const Text('초기화'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 17, color: AppTheme.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
