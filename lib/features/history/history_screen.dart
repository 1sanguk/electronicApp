import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/daily_summary.dart';
import '../../data/models/measurement.dart';
import '../../shared/providers.dart';
import 'widgets/daily_chart_widget.dart';
import 'widgets/hourly_chart_widget.dart';
import 'widgets/monthly_chart_widget.dart';
import 'widgets/weekly_chart_widget.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          title: const Text(
            '기록',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          centerTitle: false,
          bottom: const TabBar(
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(fontSize: 14),
            tabs: [
              Tab(text: '시간별'),
              Tab(text: '일간'),
              Tab(text: '주간'),
              Tab(text: '월간'),
            ],
          ),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            _HourlyTab(),
            _DailyTab(),
            _WeeklyTab(),
            _MonthlyTab(),
          ],
        ),
      ),
    );
  }
}

// ── 시간별 탭 ─────────────────────────────────────────────────────────────────

class _HourlyTab extends ConsumerWidget {
  const _HourlyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(hourlySummariesProvider);
    return async.when(
      data: (summaries) => _TabContent(
        chart: HourlyChartWidget(summaries: summaries),
        label: '오늘 시간별 기록',
        measurementsAsync: ref.watch(measurementsForDateProvider(null)),
        showDateFilter: false,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}

// ── 일간 탭 ──────────────────────────────────────────────────────────────────

class _DailyTab extends ConsumerStatefulWidget {
  const _DailyTab();

  @override
  ConsumerState<_DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends ConsumerState<_DailyTab> {
  String? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final summariesAsync = ref.watch(dailySummariesProvider);
    return summariesAsync.when(
      data: (summaries) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DailyChartWidget(
              summaries: summaries,
              onTap: (d) => setState(() => _selectedDate = d),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate != null ? '$_selectedDate 기록' : '최근 14일 기록',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                ),
                if (_selectedDate != null)
                  TextButton(
                    onPressed: () => setState(() => _selectedDate = null),
                    child: const Text('전체 보기', style: TextStyle(fontSize: 14, color: AppTheme.primary)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedDate == null)
              // 날짜별 요약 타일 (중앙값, 1개/일)
              ...summaries.reversed.map((s) => _DailySummaryTile(
                    summary: s,
                    onTap: () => setState(() => _selectedDate = s.date),
                  ))
            else
              // 선택한 날짜의 개별 측정 기록
              Consumer(
                builder: (context, ref, _) {
                  final async = ref.watch(measurementsForDateProvider(_selectedDate));
                  return async.when(
                    data: (list) => list.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text('측정 기록이 없습니다',
                                  style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                            ),
                          )
                        : Column(children: list.map((m) => _MeasurementTile(measurement: m)).toList()),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('오류: $e'),
                  );
                },
              ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}

// ── 주간 탭 ──────────────────────────────────────────────────────────────────

class _WeeklyTab extends ConsumerWidget {
  const _WeeklyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weeklySummariesProvider);
    return async.when(
      data: (summaries) => _TabContent(
        chart: WeeklyChartWidget(summaries: summaries),
        label: '주간 평균 기록',
        measurementsAsync: ref.watch(measurementsForDateProvider(null)),
        showDateFilter: false,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}

// ── 월간 탭 ──────────────────────────────────────────────────────────────────

class _MonthlyTab extends ConsumerStatefulWidget {
  const _MonthlyTab();

  @override
  ConsumerState<_MonthlyTab> createState() => _MonthlyTabState();
}

class _MonthlyTabState extends ConsumerState<_MonthlyTab> {
  String? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    final summaries = ref.watch(monthlySummariesProvider);
    return summaries.when(
      data: (list) => _TabContent(
        chart: MonthlyChartWidget(
          summaries: list,
          onTap: (m) => setState(() => _selectedMonth = m),
        ),
        label: _selectedMonth != null ? '$_selectedMonth 기록' : '최근 24개월 기록',
        measurementsAsync: ref.watch(measurementsForDateProvider(_selectedMonth)),
        showDateFilter: true,
        onClearFilter:
            _selectedMonth != null ? () => setState(() => _selectedMonth = null) : null,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}

// ── 공통 탭 레이아웃 ──────────────────────────────────────────────────────────

class _TabContent extends StatelessWidget {
  final Widget chart;
  final String label;
  final AsyncValue<List<Measurement>> measurementsAsync;
  final bool showDateFilter;
  final VoidCallback? onClearFilter;

  const _TabContent({
    required this.chart,
    required this.label,
    required this.measurementsAsync,
    required this.showDateFilter,
    this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          chart,
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
              ),
              if (onClearFilter != null)
                TextButton(
                  onPressed: onClearFilter,
                  child: const Text('전체 보기',
                      style: TextStyle(fontSize: 14, color: AppTheme.primary)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          measurementsAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('측정 기록이 없습니다',
                        style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                  ),
                );
              }
              return Column(
                children: list.map((m) => _MeasurementTile(measurement: m)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('오류: $e'),
          ),
        ],
      ),
    );
  }
}

// ── 일간 요약 타일 (날짜별 중앙값) ───────────────────────────────────────────────

class _DailySummaryTile extends StatelessWidget {
  final DailySummary summary;
  final VoidCallback? onTap;

  const _DailySummaryTile({required this.summary, this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(summary.date);
    final label = DateFormat('M월 d일').format(date);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text('${summary.count}회 측정',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  summary.avgUa.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4, left: 3),
                  child: Text('μA', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── 측정 항목 타일 ────────────────────────────────────────────────────────────

class _MeasurementTile extends StatelessWidget {
  final Measurement measurement;
  const _MeasurementTile({required this.measurement});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              DateFormat('MM월 dd일 HH:mm:ss').format(measurement.measuredAt),
              style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                measurement.valueUa.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4, left: 3),
                child: Text('μA',
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
