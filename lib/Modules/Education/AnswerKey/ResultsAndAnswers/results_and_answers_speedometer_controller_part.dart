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

  late final _SpeedometerControllerState _state;

  SpeedometerController(double targetValue) {
    _state = _buildSpeedometerControllerState(
      targetValue: targetValue,
      tickerProvider: this,
      onTick: (value) => currentValue.value = value,
    );
  }

  @override
  void onClose() {
    _controller.dispose();
    super.onClose();
  }
}
