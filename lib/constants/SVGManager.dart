import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'asset_manager.dart';


class SvgManager {

  SvgManager._();


  static Widget get appLogo => getSVG(
      Assets.appLogo,
      semanticsLabel: 'appLogo',
      width: 200,
    height: 200
  );



  static SvgPicture getSVG(String assets, {String? semanticsLabel, double? width, double? height})=> SvgPicture.asset(
    assets,
    semanticsLabel: semanticsLabel,
   width: width,
   height: height,
  );

 static Widget getSVGWithColor(String assets, Color color,{String? semanticsLabel,double? width, double? height})=> SvgPicture.asset(
    assets,
    semanticsLabel: semanticsLabel,
   colorFilter:  ColorFilter.mode(color, BlendMode.srcIn),
   width: width,
   height: height,

 );
}