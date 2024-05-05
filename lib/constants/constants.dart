import 'dart:io';
import 'package:flutter/material.dart';

extension SizeExt on double {
  SizedBox get verticalBoxPadding => SizedBox(height: this);

  SizedBox get horizontalBoxPadding => SizedBox(width: this);
}

class Px {
  final double kDefaultDuration = .25;

  static const toolBar = 80.0;

  double get statusBarSize => Platform.isIOS ? 50 : 35.0;

  double get extendSizeBodyBehindAppBar => toolBar + statusBarSize;

  final kDefault = 0.0;

  final k1 = 1.0;
  final k2 = 2.0;
  final k3 = 3.0;
  final k4 = 4.0;
  final k5 = 5.0;
  final k6 = 6.0;
  final k7 = 7.0;
  final k8 = 8.0;
  final k9 = 9.0;
  final k10 = 10.0;

  final k11 = 11.0;
  final k12 = 12.0;
  final k13 = 13.0;
  final k14 = 14.0;
  final k15 = 15.0;
  final k18 = 18.0;
  final k20 = 20.0;

  final k21 = 21.0;
  final k22 = 22.0;
  final k24 = 24.0;
  final k25 = 25.0;
  final k26 = 26.0;
  final k27 = 27.0;
  final k28 = 28.0;
  final k29 = 29.0;
  final k30 = 30.0;
  final k32 = 32.0;
  final k36 = 36.0;
  final k40 = 40.0;
  final k42 = 42.0;
  final k43 = 43.0;
  final k44 = 44.0;
  final k45 = 45.0;
  final k47 = 47.0;
  final k48 = 48.0;
  final k50 = 50.0;
  final k55 = 55.0;
  final k60 = 60.0;
  final k70 = 70.0;
  final k80 = 80.0;
  final k85 = 85.0;
  final k90 = 90.0;
  final k92 = 92.0;
  final k100 = 100.0;
  final k110 = 110.0;
  final k150 = 150.0;
  final k250 = 250.0;
  final k300 = 300.0;
  final k350 = 350.0;

  double get toolBarHeight => toolBar;
}
extension Box on double {
  double get mm => this / 1000;

  double get cm => this / 100;

  double get m => this / 10;
}
