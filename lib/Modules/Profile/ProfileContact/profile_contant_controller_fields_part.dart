part of 'profile_contant_controller.dart';

class _ProfileContactControllerState {
  final RxBool isEmailVisible = false.obs;
  final RxBool isCallVisible = false.obs;
  Worker? userWorker;
}

extension ProfileContactControllerFieldsPart on ProfileContactController {
  RxBool get isEmailVisible => _state.isEmailVisible;
  RxBool get isCallVisible => _state.isCallVisible;
  CurrentUserService get userService => CurrentUserService.instance;
  Worker? get _userWorker => _state.userWorker;
  set _userWorker(Worker? value) => _state.userWorker = value;
}
