part of 'biography_maker_controller.dart';

class _BiographyMakerControllerState {
  final bioController = TextEditingController();
  final currentLength = 0.obs, isSaving = false.obs;
}

abstract class _BiographyMakerControllerBase extends GetxController {
  final _state = _BiographyMakerControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleBiographyMakerInit(this as BiographyMakerController);
  }

  @override
  void onClose() {
    _handleBiographyMakerClose(this as BiographyMakerController);
    super.onClose();
  }
}

extension BiographyMakerControllerFieldsPart on BiographyMakerController {
  TextEditingController get bioController => _state.bioController;
  RxInt get currentLength => _state.currentLength;
  RxBool get isSaving => _state.isSaving;
  CurrentUserService get userService => CurrentUserService.instance;
}
