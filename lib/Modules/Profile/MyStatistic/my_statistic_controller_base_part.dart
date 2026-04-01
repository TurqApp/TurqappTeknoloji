part of 'my_statistic_controller.dart';

abstract class _MyStatisticControllerBase extends GetxController {
  final _MyStatisticControllerState _state = _MyStatisticControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleMyStatisticControllerInit(this as MyStatisticController);
  }

  @override
  Future<void> refresh() async {
    await _loadAll();
  }

  @override
  void onClose() {
    _handleMyStatisticControllerClose(this as MyStatisticController);
    super.onClose();
  }

  void _handleOnInit() =>
      _MyStatisticControllerRuntimeX(this as MyStatisticController)
          .handleOnInit();

  void _handleOnClose() =>
      _MyStatisticControllerRuntimeX(this as MyStatisticController)
          .handleOnClose();

  Future<void> _loadAll() =>
      _MyStatisticControllerRuntimeX(this as MyStatisticController).loadAll();
}
