part of 'profile_contant_controller.dart';

class _ProfileContactControllerState {
  final RxBool isEmailVisible = false.obs;
  final RxBool isCallVisible = false.obs;
  final CurrentUserService userService = CurrentUserService.instance;
  Worker? userWorker;
}

extension ProfileContactControllerFieldsPart on ProfileContactController {
  RxBool get isEmailVisible => _state.isEmailVisible;
  RxBool get isCallVisible => _state.isCallVisible;
  CurrentUserService get userService => _state.userService;
  Worker? get _userWorker => _state.userWorker;
  set _userWorker(Worker? value) => _state.userWorker = value;
}
