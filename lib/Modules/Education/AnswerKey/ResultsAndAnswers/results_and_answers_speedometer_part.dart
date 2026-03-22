part of 'results_and_answers.dart';

class Speedometer extends StatefulWidget {
  final double targetValue;

  const Speedometer({super.key, required this.targetValue});

  @override
  State<Speedometer> createState() => _SpeedometerState();
}

class _SpeedometerState extends State<Speedometer> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final SpeedometerController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'speedometer_${widget.targetValue}_${identityHashCode(this)}';
    _ownsController =
        SpeedometerController.maybeFind(tag: _controllerTag) == null;
    controller = SpeedometerController.ensure(
      widget.targetValue,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = SpeedometerController.maybeFind(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<SpeedometerController>(tag: _controllerTag);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => CustomPaint(
        size: Size(MediaQuery.of(context).size.width, 200),
        painter: SpeedometerPainter(controller.currentValue.value),
      ),
    );
  }
}

class SpeedometerController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static SpeedometerController ensure(
    double targetValue, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SpeedometerController(targetValue),
      tag: tag,
      permanent: permanent,
    );
  }

  static SpeedometerController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<SpeedometerController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SpeedometerController>(tag: tag);
  }

  final double targetValue;
  final currentValue = 0.0.obs;
  late AnimationController _controller;
  late Animation<double> _animation;

  SpeedometerController(this.targetValue) {
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: targetValue,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _animation.addListener(() {
      currentValue.value = _animation.value;
    });

    _controller.forward();
  }

  @override
  void onClose() {
    _controller.dispose();
    super.onClose();
  }
}

class SpeedometerPainter extends CustomPainter {
  final double value;

  SpeedometerPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    final paintArc = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, math.pi, math.pi, false, paintArc);

    final paintNeedle = Paint()
      ..color = Colors.red
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final angle = value / 100 * 180;
    final radian = (angle + 180) * (math.pi / 180);

    final needleEnd = Offset(
      center.dx + radius * math.cos(radian),
      center.dy + radius * math.sin(radian),
    );

    canvas.drawLine(center, needleEnd, paintNeedle);

    final paintText = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    const textStyle = TextStyle(
      color: Colors.black,
      fontSize: 15,
      fontFamily: 'MontserratBold',
    );

    for (int i = 0; i <= 10; i++) {
      final number = i * 10;
      paintText.text = TextSpan(text: number.toString(), style: textStyle);
      paintText.layout();

      final numberAngle = math.pi + (i / 10) * math.pi;
      final xPos = center.dx + (radius + 20) * math.cos(numberAngle);
      final yPos = center.dy + (radius + 20) * math.sin(numberAngle);

      paintText.paint(
        canvas,
        Offset(xPos - paintText.width / 2, yPos - paintText.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
