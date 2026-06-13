# 건강 전류 측정기 (Body Current Tracker)

## 앱 개요

손가락을 화면에 올려놓으면 터치 센서 데이터를 기반으로 생체 전류값(μA)을 시뮬레이션하여 보여주는 건강 추적 앱.

- 앱 표시 이름: **건강 전류 측정기** (AndroidManifest `android:label`, iOS `CFBundleDisplayName`)
- 패키지명: `electronic_app`
- 버전: `1.0.0+1`

> 실제 의료기기가 아닌 웰니스 추적 목적의 시뮬레이션 앱입니다.

---

## 기술 스택

| 항목 | 내용 |
|------|------|
| 프레임워크 | Flutter 3.44.2 (Dart 3.12.2) |
| 상태관리 | flutter_riverpod 2.6.1 |
| 로컬 DB | sqflite 2.3.3 |
| 차트 | fl_chart 0.70.2 |
| 환경설정 저장 | shared_preferences 2.3.2 |
| 국제화 유틸 | intl 0.19.0 |
| 아이콘 생성 | flutter_launcher_icons 0.14.3 (dev) |
| 플랫폼 | iOS, Android |

---

## 주요 기능

### 측정 탭

측정 화면 상단 토글로 **단일 측정** / **연속 측정** 전환.

#### 단일 측정
- 손가락을 원형 패드에 올리고 3초 또는 5초 유지
- 터치 접촉 면적, 지속 시간, 압력 비율을 수집하여 μA 값 계산
- 측정 완료 후 저장 / 다시 측정 선택

#### 연속 측정
- 시작 버튼 → 손가락 유지 → 1초 간격으로 전류값 샘플링
- 실시간 FingerPad 위에 현재값(μA)과 경과 초수 표시
- 정지 버튼 → 꺾은선 그래프 + 평균/최소/최대 통계 확인
- 저장 버튼 → 각 샘플을 개별 Measurement로 DB 삽입

### 기록 탭

4개 탭, 모든 차트는 **가로 스크롤** 지원.

| 탭 | 데이터 범위 | 차트 종류 | 집계 방식 | 특이사항 |
|----|------------|----------|----------|---------|
| 시간별 | 오늘 자정 이후 | 꺾은선 | 시간당 중앙값 | 초기 스크롤이 현재 시간 중앙으로 이동 |
| 일간 | 최근 14일 | 꺾은선 | 일별 중앙값 | 차트 터치 시 해당 날짜 기록 필터 |
| 주간 | 최근 12주 | 막대 | 주별 중앙값 | 레이블 형식: "N월 N째주" |
| 월간 | 최근 24개월 | 막대 | 월별 중앙값 | 레이블 형식: "N월" (YYYY-MM 파싱) |

- 측정 타일 시각: `MM월 dd일 HH:mm:ss` (초 단위 표시)

### 설정 탭

| 섹션 | 항목 | 설명 |
|------|------|------|
| 후원 | 개발자 후원하기 | 하나은행 880-910769-67507 계좌번호 복사 버튼 |
| 측정 설정 | 측정 시간 | 3초 / 5초 선택 (shared_preferences 저장) |
| 데이터 | 모든 데이터 삭제 | 확인 다이얼로그 후 measurements + daily_summary 전체 삭제 |

> 측정 방식(단일/연속) 전환은 **설정이 아닌 측정 화면** 상단 토글에서 수행.

---

## 측정 알고리즘

```
기준값(base) = 42.0 μA
duration_factor = clamp(접촉시간ms / 3000, 0.7, 1.3)
radius_factor   = clamp(최대반경px / 40.0, 0.8, 1.2)
pressure_factor = lerp(0.9, 1.1, 지속압력비율)
noise           = 가우시안 노이즈 (stddev=2.5)

결과 = base × duration_factor × radius_factor × pressure_factor + noise
범위 = 28.0 ~ 92.0 μA
```

연속 측정 시 `MeasurementEngine.sampleNow()` → `TouchMeasurementService.sampleWindow()` → `computeValue()` 경로로 1초마다 샘플링.

---

## 앱 아이콘

- `assets/icon/app_icon.png` 원본 (진녹색 배경 + 지문 + 번개)
- `flutter_launcher_icons`로 Android / iOS 아이콘 자동 생성

---

## 첫 실행 데모 데이터

`main()` 에서 `seedDemoDataIfEmpty()` 호출. DB가 비어 있을 때만 실행.

- 최근 30일: 하루 2~3회 랜덤 시간 측정값 삽입
- 오늘: 2~3시간 간격으로 당일 시간별 차트용 데이터 삽입
- 난수 시드 42 (재현 가능)

---

## UI/UX 설계 원칙

- 주 타겟: **40대 이상** 사용자
- 본문 폰트 최소 **18sp**
- 터치 타겟 최소 **56×56dp**
- 고대비 색상 (배경 #F8F5F0, 텍스트 #0D2D45, Primary #1A6B5C)
- 세로 방향(Portrait) 고정

---

## 프로젝트 구조

```
lib/
├── main.dart                          # 앱 진입점, 데모 데이터 시드
├── app.dart                           # MaterialApp + BottomNav 쉘 (측정/기록/설정)
├── core/
│   ├── constants/measurement_constants.dart
│   └── theme/app_theme.dart
├── data/
│   ├── db/database_helper.dart        # SQLite 싱글턴
│   ├── models/
│   │   ├── measurement.dart
│   │   ├── daily_summary.dart
│   │   ├── measurement_method.dart    # touch / ppg / combined
│   │   └── measure_mode.dart         # single / continuous
│   └── repositories/measurement_repository.dart
├── features/
│   ├── measure/                       # 측정 화면
│   │   ├── measure_screen.dart        # 단일 측정 + 모드 토글
│   │   ├── services/
│   │   │   ├── measurement_engine.dart
│   │   │   └── touch_measurement_service.dart
│   │   └── widgets/
│   │       ├── continuous_measure_widget.dart  # 연속 측정 UI
│   │       ├── finger_pad_widget.dart
│   │       ├── scan_animation_widget.dart
│   │       └── result_display_widget.dart
│   ├── history/                       # 기록 화면
│   │   ├── history_screen.dart        # 4탭 (시간별/일간/주간/월간)
│   │   └── widgets/
│   │       ├── hourly_chart_widget.dart
│   │       ├── daily_chart_widget.dart
│   │       ├── weekly_chart_widget.dart
│   │       └── monthly_chart_widget.dart
│   └── settings/
│       └── settings_screen.dart       # AppSettings, SettingsNotifier 포함
└── shared/
    ├── providers.dart                 # Riverpod 글로벌 Provider
    └── demo_data.dart                 # 첫 실행 시 30일치 시드
```

---

## DB 스키마

### measurements 테이블
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | INTEGER PK | 자동증가 |
| measured_at | TEXT | ISO-8601 UTC |
| value_ua | REAL | 측정값 (μA) |
| method | TEXT | touch / ppg / combined |
| duration_ms | INTEGER | 측정 소요 시간 |
| touch_points | INTEGER | 접촉 포인트 수 (기본 1) |
| note | TEXT | 메모 (선택) |

### daily_summary 테이블
| 컬럼 | 타입 | 설명 |
|------|------|------|
| date | TEXT PK | YYYY-MM-DD |
| avg_ua | REAL | 일 평균 |
| min_ua | REAL | 일 최솟값 |
| max_ua | REAL | 일 최댓값 |
| count | INTEGER | 측정 횟수 |

> daily_summary는 insert 트랜잭션 내에서 실시간 갱신됨 (별도 집계 쿼리 없음).

---

## 설계 결정

| 항목 | 결정 | 이유 |
|------|------|------|
| 측정 모드 위치 | 측정 화면 상단 토글 | 설정보다 접근성이 높고, 측정 직전 맥락에서 전환하는 것이 자연스러움 |
| 차트 집계 방식 | 평균 대신 중앙값 | 이상 수치(노이즈)에 덜 민감한 중앙값이 건강 추세 파악에 적합 |
| 연속 측정 저장 | 샘플 각각 개별 Measurement | 동일한 조회/집계 로직 재사용 가능 |
| 일간 탭 범위 | 최근 14일 | 기존 7일에서 2주로 확대하여 추세 파악 용이 |
| 월간 탭 범위 | 최근 24개월 | 기존 12개월에서 2년으로 확대 |
| 데모 데이터 시드 | main()에서 DB 비어있을 때만 실행 | 첫 실행 시 차트 빈 화면 방지, 이후 실데이터와 충돌 없음 |
