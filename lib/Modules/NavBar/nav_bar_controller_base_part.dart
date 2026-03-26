part of 'nav_bar_controller.dart';

abstract class _NavBarControllerBase extends GetxController
    with GetTickerProviderStateMixin, WidgetsBindingObserver {
  final _state = _NavBarControllerState();

  @override
  void onInit() {
    super.onInit();
    _NavBarControllerSupportPart(this as NavBarController).handleOnInit();
  }

  @override
  void onClose() {
    _NavBarControllerSupportPart(this as NavBarController).handleOnClose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    (this as NavBarController)._didChangeAppLifecycleStateImpl(state);
  }
}
