part of 'story_circle.dart';

class StoryUploadingRing extends StatefulWidget {
  final double strokeWidth;
  const StoryUploadingRing({super.key, this.strokeWidth = 2});

  @override
  State<StoryUploadingRing> createState() => _StoryUploadingRingState();
}

class _StoryUploadingRingState extends State<StoryUploadingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final angle = _controller.value * 2 * math.pi * 3;
        return CustomPaint(
          painter: _StoryRingPainter(
            angle: angle,
            strokeWidth: widget.strokeWidth,
          ),
        );
      },
    );
  }
}

class _StoryRingPainter extends CustomPainter {
  final double angle;
  final double strokeWidth;
  _StoryRingPainter({required this.angle, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 2.5;

    final basePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, basePaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 1
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..shader = SweepGradient(
        colors: [
          AppColors.primaryColor,
          AppColors.secondColor,
        ],
      ).createShader(rect);

    const arcLen = math.pi * 0.9;
    canvas.drawArc(rect, angle, arcLen, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _StoryRingPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.strokeWidth != strokeWidth;
  }
}

class FluidCirclePainter extends CustomPainter {
  final double pulseValue;

  FluidCirclePainter(this.pulseValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) / 2 - 3;
    final radius = baseRadius + (pulseValue * 2);

    final gradient = SweepGradient(
      startAngle: 0.0,
      endAngle: 2 * math.pi,
      colors: [
        Colors.blue.withValues(alpha: 0.8),
        Colors.purple.withValues(alpha: 0.9),
        Colors.pink.withValues(alpha: 0.7),
        Colors.blue.withValues(alpha: 0.8),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final shader = gradient.createShader(rect);

    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 + pulseValue
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);

    final glowPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, 3.0 + (pulseValue * 2));

    canvas.drawCircle(center, radius, glowPaint);
  }

  @override
  bool shouldRepaint(FluidCirclePainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}
