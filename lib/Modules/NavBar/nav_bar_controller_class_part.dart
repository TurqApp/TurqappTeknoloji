part of 'nav_bar_controller.dart';

class NavBarController extends GetxController
    with GetTickerProviderStateMixin, WidgetsBindingObserver {
  static NavBarController ensure() => _ensureNavBarController();

  static NavBarController? maybeFind() => _maybeFindNavBarController();
  final _state = _NavBarControllerState();

  @override
  void onInit() {
    super.onInit();
    _NavBarControllerSupportPart(this).handleOnInit();
  }

  @override
  void onClose() {
    _NavBarControllerSupportPart(this).handleOnClose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _didChangeAppLifecycleStateImpl(state);
}
