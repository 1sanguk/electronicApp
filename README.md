# 건강 전류 측정기

손가락을 화면에 올려놓으면 터치 센서 데이터를 기반으로 생체 전류값(μA)을 시뮬레이션하여 보여주는 건강 추적 앱입니다.

> 실제 의료기기가 아닌 웰니스 추적 목적의 시뮬레이션 앱입니다.

---

## 주요 기능

### 단일 측정
손가락을 원형 패드에 올리고 3초 또는 5초 유지하면 μA 값을 측정합니다.

### 연속 측정
시작 버튼을 누른 뒤 손가락을 화면에 올려두면 1초 간격으로 전류값을 샘플링합니다. 정지 후 꺾은선 그래프와 평균/최소/최대 통계를 확인하고 저장할 수 있습니다.

### 기록
4개 탭(시간별 / 일간 / 주간 / 월간)으로 측정 이력을 차트로 조회합니다. 모든 차트는 가로 스크롤을 지원합니다.

### 설정
- 측정 시간: 3초 / 5초 선택
- 데이터 전체 삭제
- 개발자 후원 (하나은행 계좌번호 복사)

---

## 기술 스택

| 항목 | 내용 |
|------|------|
| 프레임워크 | Flutter 3.44.2 (Dart 3.12.2) |
| 상태관리 | flutter_riverpod 2.6.1 |
| 로컬 DB | sqflite 2.3.3 |
| 차트 | fl_chart 0.70.2 |
| 환경설정 | shared_preferences 2.3.2 |
| 플랫폼 | iOS, Android |

---

## 시작하기

```bash
flutter pub get
flutter run
```

첫 실행 시 30일치 데모 데이터가 자동으로 생성됩니다.

### 앱 아이콘 재생성

```bash
dart run flutter_launcher_icons
```

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

---

## 프로젝트 문서

자세한 설계 결정, 버전 히스토리, 다음 작업 목록은 `basicdata/` 디렉터리를 참고하세요.

- `basicdata/information.md` — 전체 구조 및 설계 결정
- `basicdata/version.md` — 버전 히스토리
- `basicdata/nexttodo.md` — 다음 작업 목록
