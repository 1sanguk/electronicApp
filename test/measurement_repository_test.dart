import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:electronic_app/data/models/measurement.dart';
import 'package:electronic_app/data/models/measurement_method.dart';
import 'package:electronic_app/data/repositories/measurement_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final repo = MeasurementRepository();

  setUp(() async {
    await repo.deleteAll();
  });

  test('queryHourlySummaries groups by local hour, not UTC hour', () async {
    final now = DateTime.now();
    await repo.insert(Measurement(
      measuredAt: now,
      valueUa: 42.0,
      method: MeasurementMethod.touch,
      durationMs: 3000,
    ));

    final hourly = await repo.queryHourlySummaries(24);

    expect(hourly, hasLength(1));
    final hourLabel = int.parse(hourly.first.date.split(' ')[1].split(':')[0]);
    expect(hourLabel, now.hour);
  });
}
