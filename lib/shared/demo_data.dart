import 'dart:math';

import '../data/models/measurement.dart';
import '../data/models/measurement_method.dart';
import '../data/repositories/measurement_repository.dart';

Future<void> seedDemoDataIfEmpty(MeasurementRepository repo) async {
  final hasData = await repo.hasAnyData();
  if (hasData) return;

  final rng = Random(42);
  final now = DateTime.now();
  final measurements = <Measurement>[];

  double val(double base) =>
      (base + (rng.nextDouble() - 0.5) * 12).clamp(28.0, 92.0);

  // Last 30 days — 2~3 measurements per day
  for (var d = 30; d >= 1; d--) {
    final day = now.subtract(Duration(days: d));
    final count = 2 + rng.nextInt(2);
    for (var i = 0; i < count; i++) {
      final h = 7 + rng.nextInt(14);
      final m = rng.nextInt(60);
      measurements.add(Measurement(
        measuredAt: DateTime(day.year, day.month, day.day, h, m),
        valueUa: double.parse(val(48 + rng.nextDouble() * 12).toStringAsFixed(1)),
        method: MeasurementMethod.touch,
        durationMs: 3000,
      ));
    }
  }

  // Today — every 2~3 hours for hourly chart
  for (var h = 0; h <= now.hour; h += 2 + rng.nextInt(2)) {
    measurements.add(Measurement(
      measuredAt: DateTime(now.year, now.month, now.day, h, rng.nextInt(60)),
      valueUa: double.parse(val(50 + rng.nextDouble() * 15).toStringAsFixed(1)),
      method: MeasurementMethod.touch,
      durationMs: 3000,
    ));
  }

  for (final m in measurements) {
    await repo.insert(m);
  }
}
