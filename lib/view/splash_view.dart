import 'package:flutter/material.dart';
import 'package:wfveflutterexample/application/app_theme/color_scheme.dart';
import 'package:wfveflutterexample/application/routes/route_generator.dart';
import 'package:wfveflutterexample/base/base_widget.dart';
import 'package:wfveflutterexample/constants/SVGManager.dart';
import 'package:wfveflutterexample/constants/constants.dart';
import 'package:wfveflutterexample/view/widgets/custom_progress_indicator.dart';

class SplashView extends BaseStateFullWidget {
   SplashView({super.key});

  @override
  SplashViewState createState() => SplashViewState();
}

class SplashViewState extends State<SplashView> {

  @override
  void initState() {
   Future.delayed(Duration(seconds: 4), (){
     widget.navigator.pushNamed(RouteManager.home);
   });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgManager.appLogo,
          widget.dimens.k10.verticalBoxPadding,
          const GradientCircularProgressIndicator(radius: 30, gradientColors: [
            ColorManager.bg,
            ColorManager.secondary,
          ],
          )
        ],
      ),),
    );
  }
}
