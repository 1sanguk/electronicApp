class DailySummary {
  final String date; // YYYY-MM-DD
  final double avgUa;
  final double minUa;
  final double maxUa;
  final int count;

  const DailySummary({
    required this.date,
    required this.avgUa,
    required this.minUa,
    required this.maxUa,
    required this.count,
  });

  Map<String, dynamic> toMap() => {
        'date': date,
        'avg_ua': avgUa,
        'min_ua': minUa,
        'max_ua': maxUa,
        'count': count,
      };

  factory DailySummary.fromMap(Map<String, dynamic> map) => DailySummary(
        date: map['date'] as String,
        avgUa: (map['avg_ua'] as num).toDouble(),
        minUa: (map['min_ua'] as num).toDouble(),
        maxUa: (map['max_ua'] as num).toDouble(),
        count: map['count'] as int,
      );
}
