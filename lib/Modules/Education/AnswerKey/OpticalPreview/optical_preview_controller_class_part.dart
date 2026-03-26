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

  final _state = _OpticalPreviewControllerState();
  final OpticalFormModel model;
  final Function? onUpdate;

  OpticalPreviewController(this.model, this.onUpdate) {
    _initialize();
  }

  void _initialize() => _initializeOpticalPreviewController(this);

  @override
  void onClose() {
    _handleOpticalPreviewClose(this);
    super.onClose();
  }

  void checkInternetConnection() => _checkOpticalPreviewInternetFacade(this);

  void setData() => _saveOpticalPreviewDataFacade(this);

  void kullaniciyiSinavGirdiKaydet() =>
      _initializeOpticalPreviewAnswersFacade(this);

  void toggleAnswer(int index, String item) =>
      _toggleOpticalPreviewAnswerFacade(this, index, item);

  void handleFinishTest(BuildContext context) =>
      _handleOpticalPreviewFinishFacade(this);

  void startTest() => _startOpticalPreviewTest(this);

  bool canStartTest() => _canStartOpticalPreviewTest(this);

  void showAlertDialog(String title, String desc) =>
      _showOpticalPreviewAlertFacade(title, desc);
}
