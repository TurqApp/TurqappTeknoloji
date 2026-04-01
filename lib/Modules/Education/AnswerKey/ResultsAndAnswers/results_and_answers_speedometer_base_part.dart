part of 'results_and_answers.dart';

abstract class _SpeedometerControllerBase extends GetxController
    with GetSingleTickerProviderStateMixin {
  _SpeedometerControllerBase(double targetValue) {
    _state = _buildSpeedometerControllerState(
      targetValue: targetValue,
      tickerProvider: this,
      onTick: (value) => _self.currentValue.value = value,
    );
  }

  late final _SpeedometerControllerState _state;
  SpeedometerController get _self => this as SpeedometerController;

  @override
  void onClose() {
    _self._controller.dispose();
    super.onClose();
  }
}
