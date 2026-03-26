part of 'current_user_service.dart';

class _CurrentUserServiceState {
  CurrentUserModel? currentUser;
  final Rx<CurrentUserModel?> currentUserRx = Rx<CurrentUserModel?>(null);
  final StreamController<CurrentUserModel?> userStreamController =
      StreamController<CurrentUserModel?>.broadcast();
  final RxInt viewSelectionRx = 1.obs;
}

extension CurrentUserServiceFieldsPart on CurrentUserService {
  CurrentUserModel? get _currentUser => _state.currentUser;
  set _currentUser(CurrentUserModel? value) => _state.currentUser = value;

  Rx<CurrentUserModel?> get currentUserRx => _state.currentUserRx;

  StreamController<CurrentUserModel?> get _userStreamController =>
      _state.userStreamController;

  Stream<CurrentUserModel?> get userStream => _userStreamController.stream;

  RxInt get viewSelectionRx => _state.viewSelectionRx;
}
