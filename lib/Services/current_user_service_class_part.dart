part of 'current_user_service.dart';

class CurrentUserService extends _CurrentUserServiceBase {
  static CurrentUserService? _instance;

  static CurrentUserService get instance => _currentUserServiceInstance();

  CurrentUserService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    _handleCurrentUserServiceClose(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _handleCurrentUserLifecycleState(this, state);
  }
}
