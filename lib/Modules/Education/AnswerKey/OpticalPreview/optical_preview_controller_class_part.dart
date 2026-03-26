part of 'optical_preview_controller_library.dart';

class OpticalPreviewController extends _OpticalPreviewControllerBase {
  OpticalPreviewController(OpticalFormModel model, Function? onUpdate)
      : super(_buildOpticalPreviewControllerState(model, onUpdate)) {
    _initializeOpticalPreviewController(this);
  }
  @override
  void onClose() {
    _handleOpticalPreviewClose(this);
    super.onClose();
  }
}
