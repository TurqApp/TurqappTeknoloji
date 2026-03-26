part of 'biography_maker_controller.dart';

class _BiographyMakerControllerState {
  final bioController = TextEditingController();
  final currentLength = 0.obs, isSaving = false.obs;
}

extension BiographyMakerControllerFieldsPart on BiographyMakerController {
  TextEditingController get bioController => _state.bioController;
  RxInt get currentLength => _state.currentLength;
  RxBool get isSaving => _state.isSaving;
  CurrentUserService get userService => CurrentUserService.instance;
}
