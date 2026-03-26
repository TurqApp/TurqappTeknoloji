part of 'results_and_answers.dart';

class _SpeedometerControllerState {
  _SpeedometerControllerState({required this.targetValue});

  final double targetValue;
  final RxDouble currentValue = 0.0.obs;
  late AnimationController controller;
  late Animation<double> animation;
}

_SpeedometerControllerState _buildSpeedometerControllerState({
  required double targetValue,
  required TickerProvider tickerProvider,
  required ValueChanged<double> onTick,
}) {
  final state = _SpeedometerControllerState(targetValue: targetValue);
  state.controller = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: tickerProvider,
  );
  state.animation = Tween<double>(
    begin: 0.0,
    end: targetValue,
  ).animate(CurvedAnimation(parent: state.controller, curve: Curves.easeInOut));
  state.animation.addListener(() {
    onTick(state.animation.value);
  });
  state.controller.forward();
  return state;
}

extension SpeedometerControllerFieldsPart on SpeedometerController {
  double get targetValue => _state.targetValue;
  RxDouble get currentValue => _state.currentValue;
  AnimationController get _controller => _state.controller;
  Animation<double> get _animation => _state.animation;
}
