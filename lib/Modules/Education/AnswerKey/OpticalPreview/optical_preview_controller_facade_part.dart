part of 'optical_preview_controller_library.dart';

OpticalPreviewController ensureOpticalPreviewController(
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

OpticalPreviewController? maybeFindOpticalPreviewController({String? tag}) =>
    _maybeFindOpticalPreviewController(tag: tag);

OpticalPreviewController _ensureOpticalPreviewController(
  OpticalFormModel model,
  Function? onUpdate, {
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindOpticalPreviewController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    OpticalPreviewController(model, onUpdate),
    tag: tag,
    permanent: permanent,
  );
}

OpticalPreviewController? _maybeFindOpticalPreviewController({String? tag}) {
  final isRegistered = Get.isRegistered<OpticalPreviewController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<OpticalPreviewController>(tag: tag);
}

void _handleOpticalPreviewClose(OpticalPreviewController controller) {
  _disposeOpticalPreviewController(controller);
}

void _checkOpticalPreviewInternetFacade(OpticalPreviewController controller) {
  _checkOpticalPreviewInternet(controller);
}

void _saveOpticalPreviewDataFacade(OpticalPreviewController controller) {
  _saveOpticalPreviewData(controller);
}

void _initializeOpticalPreviewAnswersFacade(
  OpticalPreviewController controller,
) {
  _initializeOpticalPreviewAnswers(controller);
}

void _toggleOpticalPreviewAnswerFacade(
  OpticalPreviewController controller,
  int index,
  String item,
) {
  _toggleOpticalPreviewAnswer(controller, index, item);
}

void _handleOpticalPreviewFinishFacade(OpticalPreviewController controller) {
  _handleOpticalPreviewFinish(controller);
}

void _startOpticalPreviewTest(OpticalPreviewController controller) {
  controller.selection.value = 1;
}

bool _canStartOpticalPreviewTest(OpticalPreviewController controller) {
  return controller.fullName.text.trim().length >= 6 &&
      controller.ogrenciNo.text.trim().isNotEmpty;
}

void _showOpticalPreviewAlertFacade(String title, String desc) {
  _showOpticalPreviewAlert(title, desc);
}

extension OpticalPreviewControllerFacadePart on OpticalPreviewController {
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
