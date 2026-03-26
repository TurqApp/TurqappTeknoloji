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
