import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/ResultsAndAnswers/results_and_answers_controller.dart';

class ResultsAndAnswers extends StatefulWidget {
  final OpticalFormModel model;

  const ResultsAndAnswers({super.key, required this.model});

  @override
  State<ResultsAndAnswers> createState() => _ResultsAndAnswersState();
}

class _ResultsAndAnswersState extends State<ResultsAndAnswers> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final ResultsAndAnswersController controller;

  OpticalFormModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'results_and_answers_${widget.model.docID}_${identityHashCode(this)}';
    _ownsController =
        ResultsAndAnswersController.maybeFind(tag: _controllerTag) == null;
    controller = ResultsAndAnswersController.ensure(
      model,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = ResultsAndAnswersController.maybeFind(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<ResultsAndAnswersController>(
          tag: _controllerTag,
          force: true,
        );
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              height: 70,
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(color: Colors.white),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  const AppBackButton(icon: Icons.arrow_back),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppPageTitle(
                      model.name,
                      fontSize: 25,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: Obx(
                  () => ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Container(
                          color: Colors.white,
                          alignment: Alignment.bottomCenter,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Transform.translate(
                                offset: const Offset(0, 60),
                                child: Speedometer(
                                  targetValue: controller.puan.value.toDouble(),
                                ),
                              ),
                              Container(
                                width: 80,
                                height: 50,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                ),
                                child: Text(
                                  controller.puan.value.toString(),
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 35,
                                    fontFamily: "DS",
                                    letterSpacing: 4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    controller.dogruSayisi.value.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontFamily: "MontserratBold",
                                    ),
                                  ),
                                  Text(
                                    "tests.correct".tr,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    controller.yanlisSayisi.value.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontFamily: "MontserratBold",
                                    ),
                                  ),
                                  Text(
                                    "tests.wrong".tr,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Colors.orangeAccent,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    controller.bosSayisi.value.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontFamily: "MontserratBold",
                                    ),
                                  ),
                                  Text(
                                    "tests.blank".tr,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (controller.cevaplar.isNotEmpty)
                        Column(
                          children: [
                            for (int index = 0;
                                index < model.cevaplar.length;
                                index++)
                              Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.pink.withAlpha(20),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: 35,
                                      height: 35,
                                      child: Center(
                                        child: Text(
                                          "${index + 1}.",
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 20,
                                            fontFamily: "MontserratBold",
                                          ),
                                        ),
                                      ),
                                    ),
                                    for (var item in model.max == 5
                                        ? ["A", "B", "C", "D", "E"]
                                        : ["A", "B", "C", "D"])
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4.0,
                                        ),
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: controller.cevaplar[index] ==
                                                    item
                                                ? (controller.cevaplar[index] ==
                                                        model.cevaplar[index]
                                                    ? Colors.green
                                                    : Colors.red)
                                                : (model.cevaplar[index] == item
                                                    ? Colors.white
                                                        .withValues(alpha: 0.5)
                                                    : Colors.white),
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                            border: Border.all(
                                              color: controller
                                                          .cevaplar[index] ==
                                                      item
                                                  ? (controller.cevaplar[
                                                              index] ==
                                                          model.cevaplar[index]
                                                      ? Colors.green
                                                      : Colors.red)
                                                  : (model.cevaplar[index] ==
                                                          item
                                                      ? Colors.green
                                                      : Colors.black),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Text(
                                            item,
                                            style: TextStyle(
                                              color:
                                                  controller.cevaplar[index] ==
                                                          item
                                                      ? Colors.white
                                                      : Colors.black,
                                              fontSize: 20,
                                              fontFamily: "MontserratBold",
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

    double angle = (value - 0) / 100 * 180;
    double radian = (angle + 180) * (math.pi / 180);

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
      fontFamily: "MontserratBold",
    );

    for (int i = 0; i <= 10; i++) {
      int number = i * 10;
      paintText.text = TextSpan(text: number.toString(), style: textStyle);
      paintText.layout();

      double numberAngle = math.pi + (i / 10) * math.pi;
      double xPos = center.dx + (radius + 20) * math.cos(numberAngle);
      double yPos = center.dy + (radius + 20) * math.sin(numberAngle);

      paintText.paint(
        canvas,
        Offset(xPos - paintText.width / 2, yPos - paintText.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
