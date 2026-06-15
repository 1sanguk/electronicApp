# 버전 히스토리

## v1.3.0 (2026-06-15)

### 구글 플레이 배포 준비 + 앱 리브랜딩

**앱 이름 변경**
- 앱 표시 이름을 "건강 전류 측정기" → "맨발걷기 - 전류 기록기"로 변경 (AndroidManifest, iOS Info.plist)
- Play Store 심사 리스크 회피: "체내/몸속 전류 측정", "건강 상태 측정" 등 진단기기 인상을 주는 표현 → "전류 변화 기록기" 등 트래킹 중심 표현으로 전환
- README, basicdata/information.md, basicdata/index.html(개인정보처리방침) 동기화

**패키지명 변경**
- `com.example.electronic_app` → `com.sopstudio.bodycurrent` (build.gradle.kts namespace/applicationId, MainActivity.kt 경로)

**릴리즈 서명**
- `android/key.jks` keystore 생성 (PKCS12), `android/key.properties` 작성, build.gradle.kts에 signingConfigs 추가
- `flutter build appbundle` 검증 완료 (app-release.aab)

**권한 정리**
- 미사용 CAMERA 권한/하드웨어 기능 선언 제거 (개인정보처리방침과 정합성 확보)

**앱 아이콘**
- 터치 모티프(검정 배경 + 손가락 터치 + 번개) 아이콘으로 교체, flutter_launcher_icons로 재생성

**스토어 등록정보**
- `basicdata/store_listing.md` 신규 작성 (짧은/전체 설명, 앱 이름)
- `basicdata/screenshots/` 신규: Play Store용 스크린샷 2장(측정/기록, 1200x2400, RGB) + 기능 그래픽(1024x500) 생성
- `basicdata/screenshots/promo/` 신규: 캡션 카드 스타일 스크린샷 5종(1080x1920, RGB) — 커버(앱 소개), 측정, 기록&차트, 패턴 비교(주간), 설정/보안

**앱 내부 잔여 구브랜딩 정리**
- `lib/app.dart`의 `MaterialApp.title`이 여전히 "생체 전류 측정"이었음 → "맨발걷기 - 전류 기록기"로 수정
- 설정 화면 하단 버전 표기 "생체 전류 측정 앱 v1.0.0" → "맨발걷기 - 전류 기록기 v1.0.0"로 수정

**광고 (Google AdMob) 연동**
- `google_mobile_ads: ^9.0.0` 패키지 추가
- 기존 정적 placeholder(`AdBannerPlaceholder`, "광고 영역" 텍스트만 표시)를 실제 `BannerAd` 로딩 위젯(`AdBannerWidget`)으로 교체. 로딩 전/실패 시에는 동일한 placeholder UI를 fallback으로 표시
- `lib/main.dart`에 `MobileAds.instance.initialize()` 추가
- `lib/core/constants/ad_constants.dart` 신규 — 디버그 빌드는 Google 테스트 광고 ID, 릴리즈 빌드는 `_prodAndroidBannerId`/`_prodIosBannerId` 사용
- AndroidManifest.xml / Info.plist에 AdMob App ID 메타데이터 추가, Info.plist에 `NSUserTrackingUsageDescription` 추가
- AdMob은 광고 식별자 등 기기 정보를 수집하므로 `basicdata/index.html`(개인정보처리방침)에 "광고" 항목 추가, `basicdata/store_listing.md`의 "외부 전송 없음, 인터넷 연결 불필요" 문구 제거
- `flutter analyze` / `flutter test` 통과 확인

**Android 실 AdMob ID 적용**
- AndroidManifest.xml의 `com.google.android.gms.ads.APPLICATION_ID`를 실제 App ID(`ca-app-pub-7239576101906864~9069492188`)로 교체
- `ad_constants.dart`의 `_prodAndroidBannerId`를 실제 배너 광고 단위 ID(`ca-app-pub-7239576101906864/6139200809`)로 교체
- iOS는 아직 AdMob 앱 미등록 — Google 테스트 ID 유지 (iOS 출시 전 별도 등록 필요)
- GDPR/UMP 동의(EEA·영국 사용자) 처리는 미구현 — `basicdata/nexttodo.md`에 중요 항목으로 등록

**단일 측정 — 자동 시작으로 전환**
- "측정 시작" 버튼 제거. 손가락을 패드에 올리는 순간 자동으로 측정(3초/5초) 시작
- 기존에는 버튼을 눌러 측정을 시작한 뒤 패드에 손가락을 올리는 2단계였으나, 패드 터치 한 번으로 단축
- idle/scanning 상태를 하나의 `Listener`로 묶어 손가락을 떼지 않고도 측정 중 애니메이션으로 자연스럽게 전환되도록 구현

**데모 데이터 제거**
- 첫 실행 시 30일치 가짜 측정값을 자동 삽입하던 `seedDemoDataIfEmpty()`/`shared/demo_data.dart` 제거
- 실제 배포 빌드에서 사용자가 빈 상태(기록 없음)로 앱을 시작하도록 변경

**실행 즉시 크래시 수정 (versionCode 2 → 3)**
- versionCode 2 (1.0.1+2)를 내부 테스트에 업로드 후 다운로드하면 앱을 열자마자 크래시 발생
- 원인: release `AndroidManifest.xml`에 `INTERNET`/`ACCESS_NETWORK_STATE` 권한이 없는 상태에서 `main()`이 `runApp()` 전에 `MobileAds.instance.initialize()`를 호출 → AdMob SDK가 네트워크 권한 없이 초기화되며 예외 발생 → 화면이 뜨기 전에 앱 종료
- `android/app/src/main/AndroidManifest.xml`에 `INTERNET`, `ACCESS_NETWORK_STATE` 권한 추가 (기존에는 `debug`/`profile` 매니페스트에만 있었음)
- `lib/main.dart`에서 `MobileAds.instance.initialize()`를 `runApp()` 이후 백그라운드(`unawaited`)로 이동 — 광고 SDK 초기화가 첫 프레임 렌더링을 막지 않도록 함

**실행 즉시 크래시 수정 (versionCode 3 → 4)**
- versionCode 3 (1.0.2+3)도 동일하게 화면이 뜨기 전 즉시 크래시 — `adb logcat`으로 실제 기기 대신 에뮬레이터(sdk_gphone16k_x86_64)에서 재현 성공
- 크래시 로그: `androidx.startup.InitializationProvider.onCreate()` → `WorkManagerInitializer` → "Failed to create an instance of androidx.work.impl.WorkDatabase" — Flutter/Dart 코드 실행 전, 앱 프로세스 시작 단계에서 발생
- 원인: AGP 9.0.1에서 release 빌드의 R8 코드 축소(minify)가 기본적으로 활성화됨(`build.gradle.kts`에 `isMinifyEnabled` 미설정). R8이 Room(WorkManager의 WorkDatabase)이 리플렉션으로 참조하는 클래스를 난독화/축소하면서 DB 초기화 실패
- `android/app/build.gradle.kts`의 release buildType에 `isMinifyEnabled = false`, `isShrinkResources = false` 명시
- 에뮬레이터에 release APK 설치 후 정상 실행/화면 렌더링 확인

**기록 화면 시간별 탭 시간대 오류 수정 (versionCode 4 → 5)**
- "시간별" 탭이 측정 시각을 UTC 기준 시간으로 표시 (예: 로컬 22시 측정 → "13시"로 표시, UTC+9 KST와 9시간 차이)
- 원인: `queryHourlySummaries`가 UTC로 저장된 `measured_at` 문자열에 SQLite `strftime('%Y-%m-%d %H:00', ...)`을 직접 적용해 UTC 시간을 추출 — `queryWeeklySummaries`/`queryMonthlySummaries`처럼 `.toLocal()` 변환을 거치지 않음
- `queryByDateRange`로 측정값을 가져온 뒤 Dart에서 `measuredAt.toLocal()`의 시(hour) 기준으로 그룹화하도록 재작성. "오늘 자정" 경계 비교도 `queryByDateRange`의 UTC 변환을 통해 올바르게 처리됨
- `flutter analyze` / `flutter test` 통과 확인

| 분류 | 파일 |
|------|------|
| 수정 | `lib/features/measure/measure_screen.dart` (자동 시작, 시작 버튼 제거) |
| 수정 | `lib/main.dart` (데모 데이터 시드 호출 제거, MobileAds 초기화를 runApp 이후 백그라운드로 이동) |
| 삭제 | `lib/shared/demo_data.dart` |
| 수정 | `android/app/src/main/AndroidManifest.xml` (INTERNET, ACCESS_NETWORK_STATE 권한 추가) |
| 수정 | `android/app/build.gradle.kts` (release isMinifyEnabled/isShrinkResources = false) |
| 수정 | `lib/data/repositories/measurement_repository.dart` (queryHourlySummaries 로컬 시간 기준 재작성) |

| 분류 | 파일 |
|------|------|
| 수정 | `android/app/build.gradle.kts` (applicationId, namespace, signingConfigs) |
| 수정 | `android/app/src/main/AndroidManifest.xml` (android:label, CAMERA 권한 제거, AdMob App ID 메타데이터 추가) |
| 이동 | `android/app/src/main/kotlin/com/example/electronic_app/MainActivity.kt` → `com/sopstudio/bodycurrent/MainActivity.kt` |
| 수정 | `ios/Runner/Info.plist` (CFBundleDisplayName, AdMob App ID, NSUserTrackingUsageDescription) |
| 수정 | `assets/icon/app_icon.png` (아이콘 교체) |
| 수정 | `pubspec.yaml` (description, google_mobile_ads 의존성 추가) |
| 수정 | `README.md`, `basicdata/information.md`, `basicdata/index.html`, `basicdata/store_listing.md` |
| 수정 | `lib/app.dart` (MaterialApp title, AdBannerWidget로 교체) |
| 수정 | `lib/main.dart` (MobileAds 초기화) |
| 수정 | `lib/features/settings/settings_screen.dart` (하단 버전 텍스트) |
| 추가 | `lib/core/constants/ad_constants.dart`, `lib/shared/widgets/ad_banner_widget.dart` |
| 삭제 | `lib/shared/widgets/ad_banner_placeholder.dart` |
| 추가 | `basicdata/store_listing.md` |
| 추가 | `basicdata/screenshots/screenshot_measure.png`, `screenshot_history.png`, `feature_graphic.png` |
| 추가(미커밋) | `android/key.jks`, `android/key.properties` (gitignore 처리됨) |

---

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
