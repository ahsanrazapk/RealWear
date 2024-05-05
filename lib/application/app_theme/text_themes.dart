import 'package:flutter/material.dart';

import 'color_scheme.dart';

TextTheme get textTheme => const TextTheme(
      displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, fontFamily: 'Cabin'),
      displayMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, fontFamily: 'DM Sans'),
      displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, fontFamily: 'DM Sans'),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, fontFamily: 'DM Sans'),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'DM Sans'),
      titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, fontFamily: 'DM Sans'),
      bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'DM Sans'),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, fontFamily: 'DM Sans'),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, fontFamily: 'DM Sans'),
      labelLarge: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, fontFamily: 'DM Sans'),
      labelMedium: TextStyle(fontSize: 9, fontWeight: FontWeight.w400, fontFamily: 'DM Sans'),
    ).apply(displayColor: ColorManager.primary, bodyColor: ColorManager.text);
