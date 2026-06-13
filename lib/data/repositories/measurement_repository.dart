import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/measurement.dart';
import '../models/daily_summary.dart';

class MeasurementRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  // ── Insert ────────────────────────────────────────────────────────────────

  Future<int> insert(Measurement measurement) async {
    final db = await _db;
    final dateKey = _toDateKey(measurement.measuredAt);

    return db.transaction((txn) async {
      final id = await txn.insert('measurements', measurement.toMap()..remove('id'));

      final existing = await txn.query('daily_summary',
          where: 'date = ?', whereArgs: [dateKey]);

      if (existing.isEmpty) {
        await txn.insert('daily_summary', {
          'date': dateKey,
          'avg_ua': measurement.valueUa,
          'min_ua': measurement.valueUa,
          'max_ua': measurement.valueUa,
          'count': 1,
        });
      } else {
        final prev = DailySummary.fromMap(existing.first);
        final newCount = prev.count + 1;
        final newAvg = (prev.avgUa * prev.count + measurement.valueUa) / newCount;
        await txn.update(
          'daily_summary',
          {
            'avg_ua': newAvg,
            'min_ua': measurement.valueUa < prev.minUa ? measurement.valueUa : prev.minUa,
            'max_ua': measurement.valueUa > prev.maxUa ? measurement.valueUa : prev.maxUa,
            'count': newCount,
          },
          where: 'date = ?',
          whereArgs: [dateKey],
        );
      }
      return id;
    });
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  Future<List<Measurement>> queryByDateRange(DateTime start, DateTime end) async {
    final db = await _db;
    final rows = await db.query(
      'measurements',
      where: 'measured_at >= ? AND measured_at <= ?',
      whereArgs: [start.toUtc().toIso8601String(), end.toUtc().toIso8601String()],
      orderBy: 'measured_at DESC',
    );
    return rows.map(Measurement.fromMap).toList();
  }

  /// 시간별: 오늘 자정 이후 데이터 (시간당 중앙값)
  Future<List<DailySummary>> queryHourlySummaries(int hours) async {
    final db = await _db;
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final rows = await db.rawQuery('''
      SELECT
        strftime('%Y-%m-%d %H:00', measured_at) AS hour,
        value_ua
      FROM measurements
      WHERE measured_at >= ?
      ORDER BY hour ASC, value_ua ASC
    ''', [todayMidnight.toIso8601String()]);

    final Map<String, List<double>> grouped = {};
    for (final r in rows) {
      final key = r['hour'] as String;
      grouped.putIfAbsent(key, () => []).add((r['value_ua'] as num).toDouble());
    }

    return grouped.entries.map((e) {
      final sorted = [...e.value]..sort();
      return DailySummary(
        date: e.key,
        avgUa: _median(sorted),
        minUa: sorted.first,
        maxUa: sorted.last,
        count: sorted.length,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// 일간: 최근 N일 (일별 중앙값)
  Future<List<DailySummary>> queryDailySummaries(int days) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    final measurements = await queryByDateRange(start, end);

    final Map<String, List<double>> byDay = {};
    for (final m in measurements) {
      byDay.putIfAbsent(_toDateKey(m.measuredAt), () => []).add(m.valueUa);
    }

    return byDay.entries.map((e) {
      final sorted = [...e.value]..sort();
      return DailySummary(
        date: e.key,
        avgUa: _median(sorted),
        minUa: sorted.first,
        maxUa: sorted.last,
        count: sorted.length,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// 주간: 최근 N주 (주별 중앙값, "N월 N째주" 레이블)
  Future<List<DailySummary>> queryWeeklySummaries(int weeks) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: weeks * 7));
    final measurements = await queryByDateRange(start, end);

    final Map<String, List<double>> byWeek = {};
    final Map<String, DateTime> weekMonday = {};

    for (final m in measurements) {
      final local = m.measuredAt.toLocal();
      final monday = local.subtract(Duration(days: local.weekday - 1));
      final key = _toDateKey(monday);
      byWeek.putIfAbsent(key, () => []).add(m.valueUa);
      weekMonday[key] = DateTime(monday.year, monday.month, monday.day);
    }

    final entries = byWeek.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return entries.map((e) {
      final sorted = [...e.value]..sort();
      final monday = weekMonday[e.key]!;
      final weekOfMonth = ((monday.day - 1) ~/ 7) + 1;
      final label = '${monday.month}월 $weekOfMonth째주';
      return DailySummary(
        date: label,
        avgUa: _median(sorted),
        minUa: sorted.first,
        maxUa: sorted.last,
        count: sorted.length,
      );
    }).toList();
  }

  /// 월간: 최근 N개월 (월별 중앙값)
  Future<List<DailySummary>> queryMonthlySummaries(int months) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: months * 30));
    final measurements = await queryByDateRange(start, end);

    final Map<String, List<double>> byMonth = {};
    for (final m in measurements) {
      final local = m.measuredAt.toLocal();
      final key =
          '${local.year}-${local.month.toString().padLeft(2, '0')}';
      byMonth.putIfAbsent(key, () => []).add(m.valueUa);
    }

    final entries = byMonth.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) {
      final sorted = [...e.value]..sort();
      return DailySummary(
        date: e.key,
        avgUa: _median(sorted),
        minUa: sorted.first,
        maxUa: sorted.last,
        count: sorted.length,
      );
    }).toList();
  }

  Future<bool> hasAnyData() async {
    final db = await _db;
    final rows = await db.query('measurements', limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('measurements', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('measurements');
      await txn.delete('daily_summary');
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static double _median(List<double> sorted) {
    if (sorted.isEmpty) return 0;
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
  }

  String _toDateKey(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}
