part of 'agenda_controller.dart';

class AgendaController extends _AgendaControllerBase {
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
