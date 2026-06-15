import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/measure_mode.dart';
import '../../data/models/measurement_method.dart';
import '../../shared/providers.dart';

// ── Providers ──────────────────────────────────────────────────────────────

class AppSettings {
  final MeasurementMethod method;
  final int scanDurationSec;
  final MeasureMode measureMode;
  final bool autoSave;

  const AppSettings({
    this.method = MeasurementMethod.touch,
    this.scanDurationSec = 3,
    this.measureMode = MeasureMode.single,
    this.autoSave = false,
  });

  AppSettings copyWith({
    MeasurementMethod? method,
    int? scanDurationSec,
    MeasureMode? measureMode,
    bool? autoSave,
  }) =>
      AppSettings(
        method: method ?? this.method,
        scanDurationSec: scanDurationSec ?? this.scanDurationSec,
        measureMode: measureMode ?? this.measureMode,
        autoSave: autoSave ?? this.autoSave,
      );
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _keyMethod = 'setting_method';
  static const _keyDuration = 'setting_duration';
  static const _keyMeasureMode = 'setting_measure_mode';
  static const _keyAutoSave = 'setting_auto_save';

  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final methodName = prefs.getString(_keyMethod) ?? MeasurementMethod.touch.name;
    final duration = prefs.getInt(_keyDuration) ?? 3;
    final modeName = prefs.getString(_keyMeasureMode) ?? MeasureMode.single.name;
    final autoSave = prefs.getBool(_keyAutoSave) ?? false;
    return AppSettings(
      method: MeasurementMethod.values.byName(methodName),
      scanDurationSec: duration,
      measureMode: MeasureMode.values.byName(modeName),
      autoSave: autoSave,
    );
  }

  Future<void> setMethod(MeasurementMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMethod, method.name);
    state = AsyncData(state.value!.copyWith(method: method));
  }

  Future<void> setScanDuration(int sec) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDuration, sec);
    state = AsyncData(state.value!.copyWith(scanDurationSec: sec));
  }

  Future<void> setMeasureMode(MeasureMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMeasureMode, mode.name);
    state = AsyncData(state.value!.copyWith(measureMode: mode));
  }

  Future<void> setAutoSave(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoSave, value);
    state = AsyncData(state.value!.copyWith(autoSave: value));
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

// ── Screen ───────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final packageInfoAsync = ref.watch(packageInfoProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text(
          '설정',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            const _SectionHeader(title: '후원'),
            _SettingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '개발자 후원하기 ☕',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '카카오페이로 간편하게 후원할 수 있어요',
                    style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final uri = Uri.parse('https://open.kakao.com/o/sUlY0nzi');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE000),
                        foregroundColor: const Color(0xFF3C1E1E),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('카카오페이로 후원하기', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionHeader(title: '측정 설정'),
            _SettingCard(
              title: '측정 시간',
              child: Row(
                children: [3, 5].map((sec) {
                  final selected = settings.scanDurationSec == sec;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        onPressed: () => ref
                            .read(settingsProvider.notifier)
                            .setScanDuration(sec),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selected
                              ? AppTheme.primary
                              : Colors.transparent,
                          side: BorderSide(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                          ),
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '$sec초',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            _SettingCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '자동 측정',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          settings.autoSave
                              ? '측정 후 자동으로 저장합니다'
                              : '측정 후 저장 버튼을 눌러야 저장됩니다',
                          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: settings.autoSave,
                    activeThumbColor: AppTheme.primary,
                    onChanged: (value) =>
                        ref.read(settingsProvider.notifier).setAutoSave(value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionHeader(title: '데이터'),
            _SettingCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '모든 데이터 삭제',
                  style: TextStyle(
                    fontSize: 17,
                    color: AppTheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(Icons.delete_outline, color: AppTheme.error),
                onTap: () => _confirmDelete(context, ref),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                packageInfoAsync.maybeWhen(
                  data: (info) => '맨발걷기 - 전류 기록기 v${info.version}',
                  orElse: () => '맨발걷기 - 전류 기록기',
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary.withValues(alpha:0.6),
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('오류: $e'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('데이터 삭제', style: TextStyle(fontSize: 20)),
        content: const Text(
          '모든 측정 기록이 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.',
          style: TextStyle(fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              '취소',
              style: TextStyle(fontSize: 17),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '삭제',
              style: TextStyle(color: AppTheme.error, fontSize: 17),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(measurementRepoProvider).deleteAll();
      ref.invalidate(dailySummariesProvider);
      ref.invalidate(monthlySummariesProvider);
      ref.invalidate(measurementsForDateProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('모든 데이터가 삭제되었습니다.', style: TextStyle(fontSize: 16)),
          ),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final String? title;
  final Widget child;

  const _SettingCard({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}
