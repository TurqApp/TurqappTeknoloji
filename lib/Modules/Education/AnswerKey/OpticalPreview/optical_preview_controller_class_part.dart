part of 'optical_preview_controller.dart';

class OpticalPreviewController extends GetxController {
  static OpticalPreviewController ensure(
    OpticalFormModel model,
    Function? onUpdate, {
    String? tag,
    bool permanent = false,
  }) =>
      _ensureOpticalPreviewController(
        model,
        onUpdate,
        tag: tag,
        permanent: permanent,
      );

  static OpticalPreviewController? maybeFind({String? tag}) =>
      _maybeFindOpticalPreviewController(tag: tag);

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
