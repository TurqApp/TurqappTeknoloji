part of 'current_user_service.dart';

class CurrentUserService extends GetxController with WidgetsBindingObserver {
  static CurrentUserService? _instance;

  static CurrentUserService get instance => _currentUserServiceInstance();

  static CurrentUserService? maybeFind() => _maybeFindCurrentUserService();

  static CurrentUserService ensure({bool permanent = false}) =>
      _ensureCurrentUserService(permanent: permanent);

  CurrentUserService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  final _state = _CurrentUserServiceState();

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
