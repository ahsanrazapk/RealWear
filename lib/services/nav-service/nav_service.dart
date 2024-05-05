import 'package:flutter/material.dart';
import '../../application/core/routes/routes.dart';
import 'i_nav_service.dart';

class NavService implements INavService {
  final GlobalKey<NavigatorState> _key = GlobalKey<NavigatorState>();

  @override
  Future<dynamic>? pushNamed(String path, {Object? object}) {
    return _key.currentState?.pushNamed(path, arguments: object);
  }

  @override
  Future<dynamic>? pushNamedAndRemoveUntil(String path, {Object? object}) {
    return _key.currentState?.pushNamedAndRemoveUntil(path, (route) => false, arguments: object);
  }

  @override
  Future<dynamic>? pushReplacementNamed(String path, {Object? object}) {
    return _key.currentState?.pushReplacementNamed(path, arguments: object);
  }

  @override
  GlobalKey<NavigatorState> key() => _key;

  @override
  void pop([Object? result]) {
    return _key.currentState?.pop(result);
  }

  @override
  Future<bool?> showNAVDialog(String title, String content, {bool dismissOnly = false}) async {
    return await showDialog<bool>(
      context: _key.currentContext!,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: dismissOnly
              ? <Widget>[
                  TextButton(
                    child: const Text('Dismiss'),
                    onPressed: () {
                      _key.currentState?.pop(true); // Dismiss alert dialog
                    },
                  ),
                ]
              : <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      _key.currentState?.pop(false); // Dismiss alert dialog
                    },
                  ),
                  TextButton(
                    child: const Text('Ok'),
                    onPressed: () {
                      _key.currentState?.pop(true); // Dismiss alert dialog
                    },
                  ),
                ],
        );
      },
    );
  }

  @override
  Future<T?> showModelSheet<T>(Widget widget, [bool isDismissible = true]) async {
    return await showModalBottomSheet<T?>(
        enableDrag: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        context: _key.currentContext!,
        isDismissible: isDismissible,
        builder: (builder) {
          return widget;
        });
  }

  @override
  Future<void> showLoadingDialog() async {
    return await showDialog<void>(
      context: _key.currentContext!,
      builder: (BuildContext dialogContext) {
        return const AlertDialog(
          title: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  @override
  Future<T?> showCustomDialog<T>({required Widget child, bool isDismiss = true}) async {
    return await showGeneralDialog<T?>(
      barrierLabel: "Label",
      barrierDismissible: isDismiss,
      transitionDuration: const Duration(milliseconds: 300),
      context: _key.currentContext!,
      pageBuilder: (context, anim1, anim2) {
        return Align(alignment: Alignment.center, child: child);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: const Offset(0, 0)).animate(anim1),
          child: child,
        );
      },
    );
  }

  @override
  Future<T?> showCustomAnimatedDialog<T>(PageBuilder child) {
    return showGeneralDialog<T>(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          return Transform.scale(
            scale: a1.value,
            child: Opacity(
              opacity: a1.value,
              child: widget,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
        barrierDismissible: true,
        barrierLabel: '',
        context: _key.currentContext!,
        pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>
            FadeTransition(opacity: animation, child: child()));
  }

  @override
  Future? push(Widget child) async {
    return await _key.currentState?.push(PageRouter.fadeThrough(()=> child));
  }
}
