import 'package:flutter/material.dart';
import 'dart:math';

class GradientCircularProgressIndicator extends StatefulWidget {

  final double radius;
  final List<Color> gradientColors;
  final double strokeWidth;
  const GradientCircularProgressIndicator({super.key,
    required this.radius,
    required this.gradientColors,
    this.strokeWidth = 10.0,
  });

  @override
  State<GradientCircularProgressIndicator> createState() => _GradientCircularProgressIndicatorState();
}

class _GradientCircularProgressIndicatorState extends State<GradientCircularProgressIndicator> with SingleTickerProviderStateMixin {

 late final AnimationController _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 1));

  @override
  void initState() {
    _animationController.addListener(() => setState(() {}));
    _animationController.repeat();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween(begin: 0.0, end: 1.0).animate(_animationController),
      child: CustomPaint(
        size: Size.fromRadius(widget.radius),
        painter: GradientCircularProgressPainter(
          radius: widget.radius,
          gradientColors: widget.gradientColors,
          strokeWidth: widget.strokeWidth,),
      ),
    );
  }
}

class GradientCircularProgressPainter extends CustomPainter {
  GradientCircularProgressPainter({
    required this.radius,
    required this.gradientColors,
    required this.strokeWidth,
  });
  final double radius;
  final List<Color> gradientColors;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    size = Size.fromRadius(radius);
    double offset = strokeWidth / 2;
    Rect rect = Offset(offset, offset) & Size(size.width - strokeWidth, size.height - strokeWidth);
    var paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    paint.shader =
        SweepGradient(colors: gradientColors, startAngle: 0.0, endAngle: 2 * pi)
            .createShader(rect);
    canvas.drawArc(rect, 0.0, 2 * pi, false, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}