part of 'profile_contant_controller.dart';

void _handleProfileContactControllerInit(ProfileContactController controller) {
  _syncProfileContactFromCurrentUser(controller);
  controller._userWorker = ever(controller.userService.currentUserRx, (_) {
    _syncProfileContactFromCurrentUser(controller);
  });
}

void _handleProfileContactControllerClose(ProfileContactController controller) {
  controller._userWorker?.dispose();
}

void _syncProfileContactFromCurrentUser(ProfileContactController controller) {
  final current = controller.userService.currentUser;
  controller.isEmailVisible.value = current?.mailIzin == true;
  controller.isCallVisible.value = current?.aramaIzin == true;
}

Future<void> _toggleProfileEmailVisibility(
  ProfileContactController controller,
) async {
  final next = !controller.isEmailVisible.value;
  controller.isEmailVisible.value = next;
  await controller.userService.updateFields({
    'mailIzin': next,
    'preferences.mailIzin': next,
  });
}

Future<void> _toggleProfileCallVisibility(
  ProfileContactController controller,
) async {
  final next = !controller.isCallVisible.value;
  controller.isCallVisible.value = next;
  await controller.userService.updateFields({
    'aramaIzin': next,
    'preferences.aramaIzin': next,
  });
}
