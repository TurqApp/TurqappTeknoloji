part of 'post_content_controller.dart';

class _PostContentShellState {
  _PostContentShellState({
    required this.model,
    required this.enableLegacyCommentSync,
    required this.scrollFeedToTopOnReshare,
  })  : identityState = _PostContentIdentityState.fromModel(model),
        controllerState = _PostContentControllerState(model);

  final PostsModel model;
  final bool enableLegacyCommentSync;
  final bool scrollFeedToTopOnReshare;
  final _PostContentIdentityState identityState;
  final _PostContentControllerState controllerState;
  AgendaController? agendaController;
}

extension PostContentControllerShellPart on PostContentController {
  PostsModel get model => _shellState.model;
  bool get enableLegacyCommentSync => _shellState.enableLegacyCommentSync;
  bool get scrollFeedToTopOnReshare => _shellState.scrollFeedToTopOnReshare;
  _PostContentIdentityState get _identityState => _shellState.identityState;
  _PostContentControllerState get _controllerState =>
      _shellState.controllerState;
  AgendaController get agendaController =>
      _shellState.agendaController ??= _resolveAgendaController();
}
