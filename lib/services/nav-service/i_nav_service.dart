import 'package:flutter/material.dart';

import '../../application/core/routes/routes.dart';

abstract class INavService {
  GlobalKey<NavigatorState> key();

  Future<dynamic>? pushNamedAndRemoveUntil(String path, {Object? object});

  Future<dynamic>? pushNamed(String path, {Object? object});

  Future<dynamic>? push(Widget child);

  Future<dynamic>? pushReplacementNamed(String path, {Object? object});

  void pop([Object? result]);

  Future<bool?> showNAVDialog(String title, String content, {bool dismissOnly});

  Future<void> showLoadingDialog();

  Future<T?> showCustomDialog<T>({required Widget child, bool isDismiss = true});

  Future<T?> showCustomAnimatedDialog<T>(PageBuilder child);

  Future<T?> showModelSheet<T>(Widget widget, [bool isDismissible = false]);
}
