part of 'results_and_answers.dart';

abstract class _SpeedometerControllerBase extends GetxController
    with GetSingleTickerProviderStateMixin {
  _SpeedometerControllerBase(double targetValue) {
    _state = _buildSpeedometerControllerState(
      targetValue: targetValue,
      tickerProvider: this,
      onTick: (value) => currentValue.value = value,
    );
  }

  late final _SpeedometerControllerState _state;

  @override
  void onClose() {
    _controller.dispose();
    super.onClose();
  }
}
