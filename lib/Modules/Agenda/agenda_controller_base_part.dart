part of 'agenda_controller.dart';

abstract class _AgendaControllerBase extends GetxController {
  final _state = _AgendaControllerState();

  @override
  void onInit() {
    super.onInit();
    (this as AgendaController)._handleLifecycleInit();
  }

  @override
  void onReady() {
    super.onReady();
    (this as AgendaController)._handleLifecycleReady();
  }

  @override
  void onClose() {
    (this as AgendaController)._handleLifecycleClose();
    super.onClose();
  }
}
