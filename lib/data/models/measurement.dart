import 'measurement_method.dart';

class Measurement {
  final int? id;
  final DateTime measuredAt;
  final double valueUa;
  final MeasurementMethod method;
  final int durationMs;
  final int touchPoints;
  final String? note;

  const Measurement({
    this.id,
    required this.measuredAt,
    required this.valueUa,
    required this.method,
    required this.durationMs,
    this.touchPoints = 1,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'measured_at': measuredAt.toUtc().toIso8601String(),
        'value_ua': valueUa,
        'method': method.name,
        'duration_ms': durationMs,
        'touch_points': touchPoints,
        'note': note,
      };

  factory Measurement.fromMap(Map<String, dynamic> map) => Measurement(
        id: map['id'] as int?,
        measuredAt: DateTime.parse(map['measured_at'] as String).toLocal(),
        valueUa: (map['value_ua'] as num).toDouble(),
        method: MeasurementMethod.values.byName(map['method'] as String),
        durationMs: map['duration_ms'] as int,
        touchPoints: map['touch_points'] as int? ?? 1,
        note: map['note'] as String?,
      );
}
