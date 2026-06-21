import 'package:flutter/services.dart';

/// Android에서만 동작 (BatteryManager 기반). iOS는 배터리 전압을 노출하지 않아 null 반환.
class BatteryVoltageService {
  static const _channel = MethodChannel('com.sopstudio.bodycurrent/battery');

  /// 현재 배터리 전압(mV). 읽기 실패 또는 미지원 플랫폼이면 null.
  static Future<int?> readVoltageMv() async {
    try {
      return await _channel.invokeMethod<int>('getVoltageMv');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
