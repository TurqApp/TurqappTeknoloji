part of 'agenda_controller.dart';

class AgendaController extends GetxController {
  final _state = _AgendaControllerState();
  static const Duration? _agendaWindow = null;
  static const int _reshareScanPostLimit = 12;

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
