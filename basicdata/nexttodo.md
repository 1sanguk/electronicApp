# 다음 작업 목록

## 높음

| 항목 | 설명 |
|------|------|
| 설정에서 측정 시간 반영 | 단일 측정 화면이 `settings.scanDurationSec`를 참조하지 않고 `_scanDurationSec = 3`으로 하드코딩되어 있음. `settingsProvider`에서 읽도록 수정 필요 |
| 연속 측정 손가락 감지 UX | 현재 연속 측정 중 손가락을 떼도 계속 샘플링됨. 손가락 떼었을 때 경고 또는 자동 일시정지 고려 |

## 중간

| 항목 | 설명 |
|------|------|
| 기록 탭 시간별 — 오늘 데이터 없을 때 안내 개선 | 빈 컨테이너만 표시됨. 측정 유도 메시지 또는 최근 측정 날짜 표시 |
| 데이터 삭제 후 데모 데이터 재시드 옵션 | 삭제 후 앱이 빈 상태로 남음. "데모 데이터 다시 불러오기" 버튼 추가 고려 |
| 측정값 메모 기능 | DB 스키마에 `note TEXT` 컬럼이 있으나 UI 미구현 |
| 측정 결과 공유 기능 | 단일 측정 결과를 이미지/텍스트로 공유 |
| 주간 탭 레이블 겹침 | 주 수가 많을 때 "N월 N째주" 레이블이 잘릴 수 있음. 축약 포맷 또는 45도 회전 검토 |

## 구글 플레이 배포 (콘솔 개발자 인증 완료, 2026-06-15)

| 순서 | 항목 | 설명 | 상태 |
|------|------|------|------|
| 0 | applicationId 변경 | `com.example.electronic_app` → `com.sopstudio.bodycurrent`로 변경 (build.gradle.kts, MainActivity.kt 경로, namespace) | 완료 |
| 1 | keystore 생성 | `android/key.jks` 생성 (PKCS12, 유효기간 ~2053) | 완료 |
| 2 | key.properties 설정 | `android/key.properties` 생성 (gitignore 처리됨, 비밀번호 백업 필요) | 완료 |
| 3 | build.gradle 서명 설정 | `android/app/build.gradle.kts`에 signingConfigs 추가 | 완료 |
| 4 | 릴리즈 빌드 | `flutter build appbundle` → `build/app/outputs/bundle/release/app-release.aab` (52.5MB, versionCode 2, AdMob 실 ID + 자동 측정 + 데모 데이터 제거 반영) | 완료 |
| 4.5 | AdMob 실제 ID로 교체 후 재빌드 | Android App ID/배너 광고 단위 ID 실제 값으로 교체 완료, 재빌드 완료 | 완료 |
| 4.6 | INTERNET 권한 누락으로 인한 실행 즉시 크래시 수정 | release `AndroidManifest.xml`에 `INTERNET`/`ACCESS_NETWORK_STATE` 권한 없어 `MobileAds.instance.initialize()`가 즉시 크래시 유발. 권한 추가 + `main()` 백그라운드 초기화로 방어. versionCode 3 (1.0.2+3) 재빌드 완료 | 완료 |
| 4.7 | R8 난독화로 인한 WorkManager/WorkDatabase 크래시 수정 | AGP 9.0.1에서 release 빌드 R8 minify가 기본 활성화되어 `androidx.work.impl.WorkDatabase`(Room) 초기화가 Flutter 코드 실행 전(`androidx.startup.InitializationProvider`)에 크래시. `build.gradle.kts`에 `isMinifyEnabled = false`, `isShrinkResources = false` 명시. 에뮬레이터에서 정상 실행 확인. versionCode 4 (1.0.3+4) 재빌드 완료 | 완료 |
| 4.8 | 기록 화면 시간별 탭 시간대(UTC/로컬) 오류 수정 | `queryHourlySummaries`가 UTC로 저장된 `measured_at`에 SQLite `strftime`을 직접 적용해 UTC 시간을 표시(로컬 22시 측정이 "13시"로 표시됨). `queryByDateRange` + Dart `.toLocal()` 기반으로 재작성. versionCode 5 (1.0.4+5) 재빌드 완료 | 완료 |
| 5 | 플레이 콘솔 앱 등록 | 앱 이름·설명·스크린샷·기능 그래픽 업로드. 기능 그래픽은 `basicdata/screenshots/feature_graphic.png`(1024x500). 스크린샷은 캡션 카드 5종 `basicdata/screenshots/promo/promo_1~5_*.png`(1080x1920) 권장 업로드 | 대기 (수동) |
| 6 | 개인정보처리방침 URL 등록 | `https://1sanguk.github.io/electronicApp/basicdata/` (페이지 정상 동작 확인됨) | 대기 (수동) |
| 6.5 | 앱 콘텐츠 > 광고 설정 | Play Console "앱 콘텐츠 > 광고"를 "예"로 표시, Data Safety 설문에 AdMob 데이터 수집(광고 ID 등) 반영 | 대기 (수동) |
| 7 | AAB 업로드 및 심사 제출 | versionCode 1, 2 (1.0.0+1, 1.0.1+2) 업로드됨. versionCode 2, 3은 각각 INTERNET 권한 누락 / R8 minify로 인한 WorkManager 크래시로 실행 즉시 종료됨 — versionCode 5 (1.0.4+5, 크래시 2건 + 시간별 탭 시간대 오류 모두 수정)를 업로드 필요 | 진행 중 |

**중요**: `android/key.jks`와 `android/key.properties`는 git에 포함되지 않음 (의도적). 이 키를 잃으면 앱을 업데이트할 수 없으므로 별도 백업 필요 (storePassword=keyPassword=`NtUShjViQAZ10HgWaDJKYn6T`, alias=`key`).

## AdMob 실 광고 적용

| 항목 | 설명 | 상태 |
|------|------|------|
| Android App ID 적용 | `ca-app-pub-7239576101906864~9069492188` (AndroidManifest.xml) | 완료 |
| Android 배너 광고 단위 ID 적용 | `ca-app-pub-7239576101906864/6139200809` (`ad_constants.dart`의 `_prodAndroidBannerId`) | 완료 |
| iOS App ID / 광고 단위 등록 | iOS용 AdMob 앱 미등록 — 현재 Google 테스트 ID(`_prodIosBannerId`, Info.plist `GADApplicationIdentifier`) 사용 중. iOS 출시 전 별도 등록 및 교체 필요 | 대기 |
| GDPR/UMP 동의 처리 (EEA·영국 사용자) | google_mobile_ads의 UMP(User Messaging Platform) SDK로 동의 수집이 아직 미구현. Play Store는 전 세계 배포이므로 EEA/영국 사용자에게 맞춤 광고를 동의 없이 요청하면 AdMob 정책 위반(계정 정지 리스크). `ConsentInformation.requestConsentInfoUpdate` + `ConsentForm.loadAndShowConsentFormIfRequired` 적용 필요 | 대기 (중요) |
| 재빌드 | 위 항목(특히 UMP) 반영 후 `flutter build appbundle --release` 재빌드 → "구글 플레이 배포" 표의 4.5 항목 진행 | 대기 |

## 낮음

| 항목 | 설명 |
|------|------|
| 카메라 PPG 측정 방식 | 손가락을 카메라 렌즈에 올려 측정하는 방식 구현 (camera 패키지 활용) |
| 건강 리포트 | 주간/월간 분석 요약 화면 |
| 이상 수치 알림 | 설정 가능한 임계값 초과 시 로컬 알림 |
| 다크 모드 | AppTheme에 dark variant 추가 |
| 앱 버전 자동 표시 | 설정 화면 하단 버전 텍스트를 `package_info_plus`로 pubspec.yaml 버전과 동기화 |
| iOS Info.plist 잔여 카메라 권한 정리 | `NSCameraUsageDescription` 항목이 카메라 기능 제거 후에도 남아있음. Android CAMERA 권한은 이미 제거됨 — iOS도 동일하게 정리 필요 |
