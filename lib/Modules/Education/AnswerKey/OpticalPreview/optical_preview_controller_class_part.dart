part of 'optical_preview_controller.dart';

class OpticalPreviewController extends GetxController {
  final _OpticalPreviewControllerState _state;

  OpticalPreviewController(OpticalFormModel model, Function? onUpdate)
      : _state = _buildOpticalPreviewControllerState(model, onUpdate) {
    _initializeOpticalPreviewController(this);
  }

  @override
  void onClose() {
    _handleOpticalPreviewClose(this);
    super.onClose();
  }
}
