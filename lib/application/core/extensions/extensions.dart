import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';





extension StringExtension on String {
  int toInt() => int.parse(this);

  double toFloat() => double.parse(this);

  String defaultOnEmpty([String defaultValue = ""]) => isEmpty ? defaultValue : this;

  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}



extension ContextExtension on BuildContext {

  // MediaQueryData get mediaQuery => MediaQueryData.fromView(View.of(this));
  double getHeight([double factor = 1]) {
    assert(factor != 0);
    return MediaQuery.of(this).size.height * factor;
  }

  double getWidth([double factor = 1]) {
    assert(factor != 0);
    return MediaQuery.of(this).size.width * factor;
  }

  double get height => getHeight();

  double get width => getWidth();

  TextTheme get textTheme => Theme.of(this).textTheme;

  ThemeData get theme => Theme.of(this);

  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get size => mediaQuery.size;
  double get scale => mediaQuery.devicePixelRatio;


  RelativeRect getRelativeRect(Offset offset) {
    double left = offset.dx;
    double top = offset.dy;
    double right = offset.dx;
    double bottom = offset.dy;

    return RelativeRect.fromLTRB(left, top, right, bottom);
  }
   double  gap() {
    double scale =  MediaQuery.textScaleFactorOf(this);
    return scale <= 1 ? 8 : lerpDouble(8, 4, math.min(scale - 1, 1)) ?? 1.0;
   }
}

extension DateHelpers on DateTime {
  DateTime fromTimeOfDay(TimeOfDay time) {
    return DateTime(year, month, day, time.hour, time.minute);
  }

  bool isToday() {
    final now = DateTime.now();
    return now.day == day && now.month == month && now.year == year;
  }

  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return yesterday.day == day && yesterday.month == month && yesterday.year == year;
  }

  DateTime firstDateOfTheWeek() {
    return subtract(Duration(days: weekday - 1));
  }

  DateTime lastDateOfTheWeek() {
    return add(Duration(days: DateTime.daysPerWeek - weekday));
  }

  bool isDateInCurrentMonth(int number) {
    DateTime currentDate = DateTime.now();
    return year == currentDate.year && (month >= (currentDate.month - number) && month <= currentDate.month);
  }

  DateTime lastDayOfMonth() =>
      ((month < 12) ? DateTime(year, month + 1, 1) : DateTime(year + 1, 1, 1)).subtract(const Duration(days: 1));
}

extension ClickableExtension on Widget {
  Widget onTap(
      {Key? key,VoidCallback? onTap,
      bool opaque = true,
      GestureTapDownCallback? onTapDown,
      GestureDragUpdateCallback? verticalDrag}) {
    return GestureDetector(
      key: key,
      behavior: opaque ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
      onTap: onTap,
      onTapDown: onTapDown,
      onVerticalDragUpdate: verticalDrag,
      child: this,
    );
  }
}

extension WidgetPadding on Widget {
  Widget padding(EdgeInsets edgeInsets) {
    return Padding(
      padding: edgeInsets,
      child: this,
    );
  }
}

extension TimeOfDayExtension on TimeOfDay {
  int compare(TimeOfDay other) {
    return inMinutes() - other.inMinutes();
  }

  int inMinutes() {
    return hour * 60 + minute;
  }

  bool before(TimeOfDay other) {
    return compare(other) < 0;
  }

  bool after(TimeOfDay other) {
    return compare(other) > 0;
  }

  TimeOfDay add({required int minutes}) {
    final total = inMinutes() + minutes;
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }

  TimeOfDay subtract({required int minutes}) {
    final total = inMinutes() - minutes;
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }

  bool beforeOrEqual(TimeOfDay other) {
    return compare(other) <= 0;
  }

  bool afterOrEqual(TimeOfDay other) {
    return compare(other) >= 0;
  }
}
