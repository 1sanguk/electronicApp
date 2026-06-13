import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/measurement.dart';
import '../data/repositories/measurement_repository.dart';

final measurementRepoProvider = Provider((_) => MeasurementRepository());

final hourlySummariesProvider = FutureProvider((ref) async {
  final repo = ref.read(measurementRepoProvider);
  return repo.queryHourlySummaries(24);
});

final dailySummariesProvider = FutureProvider((ref) async {
  final repo = ref.read(measurementRepoProvider);
  return repo.queryDailySummaries(14);
});

final weeklySummariesProvider = FutureProvider((ref) async {
  final repo = ref.read(measurementRepoProvider);
  return repo.queryWeeklySummaries(12);
});

final monthlySummariesProvider = FutureProvider((ref) async {
  final repo = ref.read(measurementRepoProvider);
  return repo.queryMonthlySummaries(24);
});

final measurementsForDateProvider =
    FutureProvider.family<List<Measurement>, String?>((ref, date) async {
  final repo = ref.read(measurementRepoProvider);
  if (date == null) {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 14));
    return repo.queryByDateRange(start, end);
  }
  // YYYY-MM (월간)
  if (RegExp(r'^\d{4}-\d{2}$').hasMatch(date)) {
    final parts = date.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month < 12 ? month + 1 : 1, 1)
        .subtract(const Duration(milliseconds: 1));
    return repo.queryByDateRange(start, end);
  }
  // YYYY-MM-DD (일간)
  final parsed = DateTime.parse(date);
  final start = DateTime(parsed.year, parsed.month, parsed.day);
  final end =
      start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
  return repo.queryByDateRange(start, end);
});
