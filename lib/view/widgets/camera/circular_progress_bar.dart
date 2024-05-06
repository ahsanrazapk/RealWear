import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);
class CircleProgressBar extends StatefulWidget {
  const CircleProgressBar({
    Key? key,
     required this.outerRadius,
     required this.ringsWidth,
    this.ringsColor = Colors.red,
    this.duration = const Duration(seconds: 15),
  }) : super(key: key);

  final double outerRadius;
  final double ringsWidth;
  final Color ringsColor;
  final Duration duration;

  @override
  State<StatefulWidget> createState() => CircleProgressState();
}

class CircleProgressState extends State<CircleProgressBar>
    with SingleTickerProviderStateMixin {
  final GlobalKey paintKey = GlobalKey();

    AnimationController? progressController;

  @override
  void initState() {
    progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      progressController?.forward();
      progressController?.addListener(() {

        double currentValueInSeconds =
            ( progressController?.value ?? 0.0) * (progressController?.duration?.inSeconds ?? 0);
         durationNotifier.value = Duration(seconds: (currentValueInSeconds).round());


      });
    });
  }

  @override
  void dispose() {
    progressController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = Size.square(widget.outerRadius * 2);
    return Center(
      child: AnimatedBuilder(
        animation: progressController!,
        builder: (_, __)
        {

       return CustomPaint(
        key: paintKey,
        size: size,
        painter: ProgressPainter(
          progress: progressController!.value,
          ringsWidth: widget.ringsWidth,
          ringsColor: widget.ringsColor,
        ),
      );
        }
      ),
    );
  }
}

class ProgressPainter extends CustomPainter {
  const ProgressPainter({
    required this.ringsWidth,
    required this.ringsColor,
    required this.progress,
  });

  final double ringsWidth;
  final Color ringsColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final double center = size.width / 2;
    final Offset offsetCenter = Offset(center, center);
    final double drawRadius = size.width / 2 - ringsWidth;
    final double angle = 360.0 * progress;
    final double radians = angle.toRad;

    final double outerRadius = center;
    final double innerRadius = center - ringsWidth * 2;

    final double progressWidth = outerRadius - innerRadius;
    canvas.save();
    canvas.translate(0.0, size.width);
    canvas.rotate(-90.0.toRad);
    final Rect arcRect = Rect.fromCircle(
      center: offsetCenter,
      radius: drawRadius,
    );
    final Paint progressPaint = Paint()
      ..color = ringsColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = progressWidth;
    canvas
      ..drawArc(arcRect, 0, radians, false, progressPaint)
      ..restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

extension _MathExtension on double {
  double get toRad => this * (math.pi / 180.0);
}
