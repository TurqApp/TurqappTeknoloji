part of 'optical_preview_controller.dart';

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
