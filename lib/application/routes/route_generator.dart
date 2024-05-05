import 'package:flutter/material.dart';
import 'package:wfveflutterexample/application/core/routes/routes.dart';
import 'package:wfveflutterexample/view/home_page.dart';
import 'package:wfveflutterexample/view/realware/dashboard.dart';
import 'package:wfveflutterexample/view/splash_view.dart';

class RouteManager {
  static const rInitial = '/';
  static const home = '/home';
}

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case RouteManager.rInitial:
        return PageRouter.fadeScale(() => SplashView());
      case RouteManager.home:
        return PageRouter.fadeScale(() => MyHomePage());
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> generateRouteRealware(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case RouteManager.rInitial:
        return PageRouter.fadeScale(() => SplashView());
      case RouteManager.home:
        return PageRouter.fadeScale(() => const Dashboard());
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Container(color: Colors.white, child: const Text('Page Not Found')),
        ),
      );
    });
  }
}
