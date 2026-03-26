part of 'agenda_controller.dart';

AgendaController? maybeFindAgendaController() {
  final isRegistered = Get.isRegistered<AgendaController>();
  if (!isRegistered) return null;
  return Get.find<AgendaController>();
}

AgendaController ensureAgendaController({bool permanent = false}) {
  final existing = maybeFindAgendaController();
  if (existing != null) return existing;
  return Get.put(AgendaController(), permanent: permanent);
}

extension AgendaControllerFacadePart on AgendaController {
  int get fetchLimit => 50;

  AgendaShuffleCacheService get _shuffleCache =>
      AgendaShuffleCacheService.ensure();
}
