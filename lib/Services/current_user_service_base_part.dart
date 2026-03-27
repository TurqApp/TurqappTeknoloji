part of 'current_user_service.dart';

abstract class _CurrentUserServiceBase extends GetxService
    with WidgetsBindingObserver {
  final _state = _CurrentUserServiceState();

  @override
  void onClose() {
    _handleCurrentUserServiceClose(this as CurrentUserService);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _handleCurrentUserLifecycleState(this as CurrentUserService, state);
  }
}
