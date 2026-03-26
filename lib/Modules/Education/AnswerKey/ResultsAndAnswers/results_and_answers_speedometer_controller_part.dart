part of 'results_and_answers.dart';

class SpeedometerController extends GetxController
    with GetSingleTickerProviderStateMixin {
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
