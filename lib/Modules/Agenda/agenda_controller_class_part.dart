part of 'agenda_controller.dart';

class AgendaController extends _AgendaControllerBase {
  static const Duration? _agendaWindow = null;
  static const int _reshareScanPostLimit = 12;

  RxList<PostsModel> get agendaList => _state.agendaList;

  RxInt get centeredIndex => _state.centeredIndex;

  int? get lastCenteredIndex => _state.lastCenteredIndex;
  set lastCenteredIndex(int? value) => _state.lastCenteredIndex = value;
}
