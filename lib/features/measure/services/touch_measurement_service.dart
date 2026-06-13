import 'dart:math';

import '../../../core/constants/measurement_constants.dart';

class TouchMeasurementResult {
  final int contactDurationMs;
  final double maxTouchRadiusPx;
  final double sustainedPressureRatio;

  const TouchMeasurementResult({
    required this.contactDurationMs,
    required this.maxTouchRadiusPx,
    required this.sustainedPressureRatio,
  });
}

class TouchMeasurementService {
  DateTime? _contactStart;
  int _totalContactMs = 0;
  int _scanDurationMs = 0;
  double _maxRadius = 0.0;
  bool _isTracking = false;

  void startScan(int scanDurationMs) {
    _scanDurationMs = scanDurationMs;
    _totalContactMs = 0;
    _maxRadius = 0.0;
    _isTracking = true;
    _contactStart = null;
  }

  void onPointerDown(double radiusMajor) {
    if (!_isTracking) return;
    _contactStart = DateTime.now();
    if (radiusMajor > _maxRadius) _maxRadius = radiusMajor;
  }

  void onPointerMove(double radiusMajor) {
    if (!_isTracking) return;
    if (radiusMajor > _maxRadius) _maxRadius = radiusMajor;
  }

  void onPointerUp() {
    if (!_isTracking || _contactStart == null) return;
    _totalContactMs += DateTime.now().difference(_contactStart!).inMilliseconds;
    _contactStart = null;
  }

  TouchMeasurementResult finalize() {
    _isTracking = false;
    if (_contactStart != null) {
      _totalContactMs += DateTime.now().difference(_contactStart!).inMilliseconds;
      _contactStart = null;
    }

    final ratio = _scanDurationMs > 0
        ? (_totalContactMs / _scanDurationMs).clamp(0.0, 1.0)
        : 0.5;

    return TouchMeasurementResult(
      contactDurationMs: _totalContactMs,
      maxTouchRadiusPx: _maxRadius,
      sustainedPressureRatio: ratio,
    );
  }

  void stopTracking() {
    _isTracking = false;
    _contactStart = null;
  }

  TouchMeasurementResult sampleWindow() {
    final now = DateTime.now();
    var contactMs = _totalContactMs;
    var radius = _maxRadius;

    if (_contactStart != null) {
      contactMs += now.difference(_contactStart!).inMilliseconds;
      _contactStart = now;
    }

    _totalContactMs = 0;
    _maxRadius = 0.0;

    final ratio = (contactMs / 1000.0).clamp(0.0, 1.0);
    return TouchMeasurementResult(
      contactDurationMs: contactMs,
      maxTouchRadiusPx: radius,
      sustainedPressureRatio: ratio,
    );
  }

  double computeValue(TouchMeasurementResult result) {
    const base = MeasurementConstants.baseValueUa;

    final durationFactor = (result.contactDurationMs / 3000.0).clamp(0.7, 1.3);

    final radiusFactor = result.maxTouchRadiusPx > 0
        ? (result.maxTouchRadiusPx / MeasurementConstants.normalRadiusPx).clamp(0.8, 1.2)
        : 1.0;

    final pressureFactor = _lerp(0.9, 1.1, result.sustainedPressureRatio);

    final noise = _gaussianNoise();

    final value = base * durationFactor * radiusFactor * pressureFactor + noise;
    return value.clamp(MeasurementConstants.minValueUa, MeasurementConstants.maxValueUa);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double _gaussianNoise() {
    final rng = Random(DateTime.now().millisecondsSinceEpoch);
    final u1 = rng.nextDouble();
    final u2 = rng.nextDouble();
    final z = sqrt(-2.0 * log(u1 + 1e-10)) * cos(2.0 * pi * u2);
    return z * MeasurementConstants.noiseStdDev;
  }
}
