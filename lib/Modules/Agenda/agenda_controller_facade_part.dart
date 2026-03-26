part of 'agenda_controller.dart';

extension AgendaControllerFacadePart on AgendaController {
  int get fetchLimit => 50;

  AgendaShuffleCacheService get _shuffleCache =>
      AgendaShuffleCacheService.ensure();
}
