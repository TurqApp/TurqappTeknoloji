part of 'current_user_service.dart';

abstract class _CurrentUserServiceBase extends GetxController
    with WidgetsBindingObserver {
  final _state = _CurrentUserServiceState();
}
