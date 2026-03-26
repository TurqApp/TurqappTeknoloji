part of 'agenda_controller.dart';

class AgendaController extends GetxController {
  final _state = _AgendaControllerState();
  static const Duration? _agendaWindow = null;
  static const int _reshareScanPostLimit = 12;

  RxList<PostsModel> get agendaList => _state.agendaList;
  RxInt get centeredIndex => _state.centeredIndex;
  int? get lastCenteredIndex => _state.lastCenteredIndex;
  set lastCenteredIndex(int? value) => _state.lastCenteredIndex = value;
  RxBool get isMuted => _state.isMuted;
  RxBool get pauseAll => _state.pauseAll;

  @override
  void onInit() {
    super.onInit();
    _handleLifecycleInit();
  }

  @override
  void onReady() {
    super.onReady();
    _handleLifecycleReady();
  }

  @override
  void onClose() {
    _handleLifecycleClose();
    super.onClose();
  }
}
