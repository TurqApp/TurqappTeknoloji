part of 'agenda_controller.dart';

class AgendaController extends GetxController {
  static AgendaController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(AgendaController(), permanent: permanent);
  }

  static AgendaController? maybeFind() {
    final isRegistered = Get.isRegistered<AgendaController>();
    if (!isRegistered) return null;
    return Get.find<AgendaController>();
  }

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
