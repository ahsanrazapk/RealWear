import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wfveflutterexample/application/app_theme/app_themes.dart';
import 'package:wfveflutterexample/application/app_theme/color_scheme.dart';
import 'package:wfveflutterexample/application/core/extensions/extensions.dart';
import 'package:wfveflutterexample/application/main_config.dart';
import 'package:wfveflutterexample/application/routes/route_generator.dart';
import 'package:wfveflutterexample/base/base_widget.dart';
import 'package:wfveflutterexample/common/verification_type.dart';

void setPreferredOrientations(PlatformType platformType) {
  if (platformType == PlatformType.realwear) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  } else {
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark
      .copyWith(statusBarColor: ColorManager.bg, statusBarIconBrightness: Brightness.dark, statusBarBrightness: Brightness.dark));
  await initMainServiceLocator();
  PlatformType platformType = await getPlatformType();
  setPreferredOrientations(platformType);
  runApp(MyApp(
    platformType: platformType,
  ));
}

class MyApp extends BaseStateLessWidget {
  final PlatformType platformType;
  MyApp({super.key, required this.platformType});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
            title: "Final Round",
            scrollBehavior: MyBehavior(),
            theme: lightTheme,
            debugShowCheckedModeBanner: false,
            initialRoute: RouteManager.rInitial,
            onGenerateRoute: platformType == PlatformType.realwear ? RouteGenerator.generateRouteRealware : RouteGenerator.generateRoute,
            navigatorKey: navigator.key())
        .onTap(onTap: () {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
