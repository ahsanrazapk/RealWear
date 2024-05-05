import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

enum PlatformType { android, ios, realwear }

Future<PlatformType> getPlatformType() async {
  if (Platform.isAndroid) {
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
