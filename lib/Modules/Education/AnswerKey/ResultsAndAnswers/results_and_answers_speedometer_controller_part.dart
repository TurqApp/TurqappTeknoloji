part of 'results_and_answers.dart';

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
