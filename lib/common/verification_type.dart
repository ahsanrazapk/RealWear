import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

extension PT on PlatformType{
  bool get isIOS => this == PlatformType.ios;

  bool get isAndroid => this == PlatformType.android;

  bool get isMobile => this == PlatformType.android || this == PlatformType.ios;

  bool get isWeb => kIsWeb;
}


enum PlatformType { android, ios, realwear, web, desktop }

Future<PlatformType> getPlatformType() async {
  if (kIsWeb) {
    return PlatformType.web;
  } else if (Platform.isWindows) {
    return PlatformType.desktop;
  } else if (Platform.isAndroid) {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    if (androidInfo.manufacturer.toLowerCase().contains("realwear") ||
        androidInfo.manufacturer.toLowerCase().contains("moziware") ||
        androidInfo.manufacturer.toUpperCase().contains("QUALCOMM")) {
      return PlatformType.realwear;
    }
    return PlatformType.android;
  } else if (Platform.isIOS) {
    return PlatformType.ios;
  }
  return PlatformType.android;
}
