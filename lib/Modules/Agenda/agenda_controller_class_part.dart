part of 'agenda_controller.dart';

class AgendaController extends _AgendaControllerBase {
  RxList<PostsModel> get agendaList => _state.agendaList;
  RxInt get centeredIndex => _state.centeredIndex;
  int? get lastCenteredIndex => _state.lastCenteredIndex;
  set lastCenteredIndex(int? value) => _state.lastCenteredIndex = value;
  RxBool get isMuted => _state.isMuted;
  RxBool get pauseAll => _state.pauseAll;
}
