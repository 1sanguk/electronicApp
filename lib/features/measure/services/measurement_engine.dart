import '../../../data/models/measurement_method.dart';
import 'touch_measurement_service.dart';

class MeasurementEngine {
  final TouchMeasurementService _touchService = TouchMeasurementService();

  void startScan(int scanDurationMs) {
    _touchService.startScan(scanDurationMs);
  }

  void onPointerDown(double radiusMajor) {
    _touchService.onPointerDown(radiusMajor);
  }

  void onPointerMove(double radiusMajor) {
    _touchService.onPointerMove(radiusMajor);
  }

  void onPointerUp() {
    _touchService.onPointerUp();
  }

  double sampleNow() {
    final result = _touchService.sampleWindow();
    return _touchService.computeValue(result);
  }

  void stopTracking() => _touchService.stopTracking();

  MeasurementEngineResult finalize(MeasurementMethod method, int scanDurationMs) {
    final touchResult = _touchService.finalize();
    final touchValue = _touchService.computeValue(touchResult);

    return MeasurementEngineResult(
      valueUa: touchValue,
      method: method,
      durationMs: scanDurationMs,
      touchPoints: 1,
    );
  }
}

class MeasurementEngineResult {
  final double valueUa;
  final MeasurementMethod method;
  final int durationMs;
  final int touchPoints;

  const MeasurementEngineResult({
    required this.valueUa,
    required this.method,
    required this.durationMs,
    required this.touchPoints,
  });
}
