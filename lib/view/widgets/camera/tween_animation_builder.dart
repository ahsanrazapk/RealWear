import 'package:flutter/material.dart';

class CustomTweenAnimationBuilder<A, B> extends StatelessWidget {
  const CustomTweenAnimationBuilder({
    Key? key,
      required this.firstTween,
      required this.secondTween,
      required this.builder,
    this.firstTweenDuration = kThemeAnimationDuration,
    this.secondTweenDuration = kThemeAnimationDuration,
    this.firstTweenCurve = Curves.linear,
    this.secondTweenCurve = Curves.linear,
  }) : super(key: key);

  final Tween<A> firstTween;
  final Tween<B> secondTween;
  final Duration firstTweenDuration;
  final Duration secondTweenDuration;
  final Curve firstTweenCurve;
  final Curve secondTweenCurve;
  final Widget Function(BuildContext, A, B) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<A>(
      tween: firstTween,
      curve: firstTweenCurve,
      duration: firstTweenDuration,
      builder: (__, A first, _) => TweenAnimationBuilder<B>(
        tween: secondTween,
        curve: secondTweenCurve,
        duration: secondTweenDuration,
        builder: (_, B second, __) => builder(context, first, second),
      ),
    );
  }
}
