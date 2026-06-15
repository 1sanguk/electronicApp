import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ElectronicApp());
  // 광고 SDK 초기화는 첫 프레임 렌더링을 막지 않도록 백그라운드에서 수행
  unawaited(MobileAds.instance.initialize());
}
