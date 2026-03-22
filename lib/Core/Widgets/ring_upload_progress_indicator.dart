import 'package:flutter/material.dart';
import 'dart:math' as math;

class RingUploadProgressIndicator extends StatefulWidget {
  final Widget child;
  final bool isUploading;
  final double progress;
  final double size;
  final double strokeWidth;

  const RingUploadProgressIndicator({
    super.key,
    required this.child,
    required this.isUploading,
    required this.progress,
    this.size = 22.0,
    this.strokeWidth = 2.0,
  });

  @override
  State<RingUploadProgressIndicator> createState() =>
      _RingUploadProgressIndicatorState();
}

class _RingUploadProgressIndicatorState
    extends State<RingUploadProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.isUploading) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(RingUploadProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isUploading && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!widget.isUploading && _rotationController.isAnimating) {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isUploading) {
      return widget.child;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationController.value * 2 * math.pi,
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingUploadProgressPainter(
                  progress: widget.progress,
                  strokeWidth: widget.strokeWidth,
                ),
              ),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _RingUploadProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  _RingUploadProgressPainter({
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final gradient = const SweepGradient(
      colors: [
        Color(0xFF00D4D4),
        Color(0xFF0094D4),
        Color(0xFF00D4D4),
      ],
      stops: [0.0, 0.5, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingUploadProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
