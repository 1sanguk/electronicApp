import 'dart:io';

import 'package:flutter/foundation.dart';

/// AdMob 광고 단위 ID.
///
/// 디버그 빌드에서는 Google 공식 테스트 광고 단위를 사용한다.
/// 릴리즈 빌드에서는 본인의 AdMob 배너 광고 단위 ID를 사용한다.
/// (Android는 AndroidManifest.xml의 AdMob App ID와 함께 적용됨)
///
/// iOS는 아직 별도의 AdMob 앱/광고 단위가 등록되지 않아 Google 테스트 ID를
/// 그대로 사용 중이다. iOS 출시 전 _prodIosBannerId와 Info.plist의
/// GADApplicationIdentifier를 본인의 iOS AdMob ID로 교체해야 한다.
class AdConstants {
  static const String _testAndroidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testIosBannerId = 'ca-app-pub-3940256099942544/2934735716';

  static const String _prodAndroidBannerId = 'ca-app-pub-7239576101906864/6139200809';
  static const String _prodIosBannerId = 'ca-app-pub-3940256099942544/2934735716';

  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? _testAndroidBannerId : _testIosBannerId;
    }
    return Platform.isAndroid ? _prodAndroidBannerId : _prodIosBannerId;
  }
}
