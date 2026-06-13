# 버전 히스토리

## v1.2.0 (2026-06-13)

### 연속 측정 모드 및 기록 화면 전면 개편

**앱 이름 변경**
- 앱 표시 이름을 "건강 전류 측정기"로 변경 (AndroidManifest, iOS Info.plist)

**측정 기능**
- 단일 측정 / 연속 측정 모드 추가 (측정 화면 상단 토글)
- 연속 측정: 시작 → 1초마다 샘플링 → 정지 → 그래프+통계 확인 → 저장
- 연속 측정 저장 시 각 샘플을 개별 Measurement로 DB 삽입
- 설정 화면에서 측정 방식 선택 항목 제거 (측정 화면으로 이동)

**기록 화면**
- 탭 구성 변경: 일간/월간 2탭 → 시간별/일간/주간/월간 4탭
- 모든 차트에 가로 스크롤 적용
- 시간별 탭: 오늘 자정 이후 데이터, 초기 스크롤이 현재 시간 중앙으로 이동
- 주간 탭 신규: "N월 N째주" 레이블, 중앙값 집계
- 일간 탭: 최근 7일 → 14일로 확대, 집계 방식 평균 → 중앙값
- 월간 탭: 최근 12개월 → 24개월로 확대, 집계 방식 평균 → 중앙값, YYYY-MM 포맷 버그 수정
- 측정 타일 시각 표시 형식 변경: HH:mm → HH:mm:ss (초 단위)

**설정 화면**
- 후원하기 카드 추가 (하나은행 계좌번호 클립보드 복사)
- 측정 방식 선택 항목 제거

**앱 아이콘**
- flutter_launcher_icons로 커스텀 아이콘 생성 (진녹색 배경 + 지문 + 번개)
- `assets/icon/app_icon.png` 원본, Android/iOS 모두 적용

**데모 데이터**
- 첫 실행 시 30일치 데모 데이터 자동 시드 (`seedDemoDataIfEmpty`)
- 오늘 당일 시간별 차트용 데이터도 함께 생성

| 분류 | 파일 |
|------|------|
| 추가 | `lib/features/measure/widgets/continuous_measure_widget.dart` |
| 추가 | `lib/features/history/widgets/hourly_chart_widget.dart` |
| 추가 | `lib/features/history/widgets/weekly_chart_widget.dart` |
| 추가 | `lib/data/models/measure_mode.dart` |
| 추가 | `lib/shared/demo_data.dart` |
| 수정 | `lib/features/measure/measure_screen.dart` (모드 토글 추가) |
| 수정 | `lib/features/history/history_screen.dart` (4탭, 측정 타일 HH:mm:ss) |
| 수정 | `lib/features/settings/settings_screen.dart` (후원 카드, 측정 방식 제거) |
| 수정 | `lib/data/repositories/measurement_repository.dart` (hourly/weekly/monthly 쿼리 추가, 중앙값 집계) |
| 수정 | `lib/shared/providers.dart` (hourly/weekly provider 추가) |
| 수정 | `lib/main.dart` (seedDemoDataIfEmpty 호출) |
| 수정 | `lib/features/history/widgets/monthly_chart_widget.dart` (YYYY-MM 파싱 수정) |
| 수정 | `android/app/src/main/AndroidManifest.xml` (android:label 변경) |
| 수정 | `ios/Runner/Info.plist` (CFBundleDisplayName 변경) |
| 수정 | `pubspec.yaml` (flutter_launcher_icons dev dependency 추가) |

---

## v1.0.0 (2026-06-13)

### 최초 릴리즈

**측정 기능**
- 터치 방식 생체 전류 시뮬레이션 측정 구현
- 3초 / 5초 측정 시간 선택
- 측정 완료 후 저장 / 다시 측정 지원

**기록 기능**
- 일간 기록: 최근 7일 꺾은선 그래프 (fl_chart)
- 월간 기록: 최근 12개월 막대 그래프 (fl_chart)
- 측정 목록 상세 조회

**설정 기능**
- 측정 방법 전환 (터치 / 카메라 / 복합)
- 측정 시간 선택 (3초 / 5초)
- 모든 데이터 삭제

**기술 기반**
- Flutter 3.44.2 / Dart 3.12.2
- Riverpod 2.6.1 상태관리
- SQLite (sqflite) 로컬 저장
- iOS / Android 지원
