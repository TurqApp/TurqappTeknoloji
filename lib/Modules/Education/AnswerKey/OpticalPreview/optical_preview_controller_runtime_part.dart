part of 'optical_preview_controller_library.dart';

class _OpticalPreviewControllerState {
  _OpticalPreviewControllerState({
    required this.model,
    required this.onUpdate,
  });

  final OpticalFormModel model;
  final Function? onUpdate;
  final opticalFormRepository = ensureOpticalFormRepository();
  final cevaplar = <String>[].obs;
  final isConnected = true.obs;
  final selection = 0.obs;
  final fullName = TextEditingController();
  final ogrenciNo = TextEditingController();
  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;
}

_OpticalPreviewControllerState _buildOpticalPreviewControllerState(
  OpticalFormModel model,
  Function? onUpdate,
) {
  return _OpticalPreviewControllerState(
    model: model,
    onUpdate: onUpdate,
  );
}

extension OpticalPreviewControllerFieldsPart on OpticalPreviewController {
  OpticalFormModel get model => _state.model;
  Function? get onUpdate => _state.onUpdate;
  OpticalFormRepository get _opticalFormRepository =>
      _state.opticalFormRepository;
  RxList<String> get cevaplar => _state.cevaplar;
  RxBool get isConnected => _state.isConnected;
  RxInt get selection => _state.selection;
  TextEditingController get fullName => _state.fullName;
  TextEditingController get ogrenciNo => _state.ogrenciNo;
  StreamSubscription<List<ConnectivityResult>>? get _connectivitySubscription =>
      _state.connectivitySubscription;
  set _connectivitySubscription(
    StreamSubscription<List<ConnectivityResult>>? value,
  ) =>
      _state.connectivitySubscription = value;
}

abstract class _OpticalPreviewControllerBase extends GetxController {
  _OpticalPreviewControllerBase(this._state);

  final _OpticalPreviewControllerState _state;
}

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

void _initializeOpticalPreviewController(OpticalPreviewController controller) {
  controller.cevaplar.value = List.generate(
    controller.model.cevaplar.length,
    (_) => '',
  );
  _initializeOpticalPreviewAnswers(controller);
  _checkOpticalPreviewInternet(controller);
}

void _disposeOpticalPreviewController(OpticalPreviewController controller) {
  controller._connectivitySubscription?.cancel();
  controller.fullName.dispose();
  controller.ogrenciNo.dispose();
}

void _checkOpticalPreviewInternet(OpticalPreviewController controller) {
  controller._connectivitySubscription =
      Connectivity().onConnectivityChanged.listen((results) {
    controller.isConnected.value =
        results.any((r) => r != ConnectivityResult.none);
  });
}

void _saveOpticalPreviewData(OpticalPreviewController controller) {
  controller._opticalFormRepository
      .saveUserAnswers(
        controller.model.docID,
        CurrentUserService.instance.effectiveUserId,
        answers: controller.cevaplar.toList(growable: false),
        ogrenciNo: controller.ogrenciNo.text,
        fullName: controller.fullName.text,
      )
      .then((_) => Get.back());
}

void _initializeOpticalPreviewAnswers(OpticalPreviewController controller) {
  controller._opticalFormRepository.initializeUserAnswers(
    controller.model.docID,
    CurrentUserService.instance.effectiveUserId,
    controller.model.cevaplar.length,
  );
}

void _toggleOpticalPreviewAnswer(
  OpticalPreviewController controller,
  int index,
  String item,
) {
  if (controller.cevaplar[index] == item) {
    controller.cevaplar[index] = '';
  } else {
    controller.cevaplar[index] = item;
  }
}

void _handleOpticalPreviewFinish(OpticalPreviewController controller) {
  if (controller.isConnected.value) {
    controller.setData();
  } else {
    _showOpticalPreviewAlert(
      'answer_key.turn_on_internet_title'.tr,
      'answer_key.turn_on_internet_body'.tr,
    );
  }
}

void _showOpticalPreviewAlert(String title, String desc) {
  infoAlert(
    title: title,
    message: desc,
  );
}
