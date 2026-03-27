part of 'post_sharers_controller.dart';

abstract class _PostSharersControllerBase extends GetxController {
  _PostSharersControllerBase({required String postID})
      : _state = _PostSharersControllerState(postID: postID);

  final _PostSharersControllerState _state;

  @override
  void onInit() {
    super.onInit();
    (this as PostSharersController)._handlePostSharersOnInit();
  }

  @override
  void onClose() {
    (this as PostSharersController)._handlePostSharersOnClose();
    super.onClose();
  }
}

class PostSharersController extends _PostSharersControllerBase {
  PostSharersController({required super.postID});
}

PostSharersController ensurePostSharersController({
  required String postID,
  String? tag,
  bool permanent = false,
}) =>
    maybeFindPostSharersController(tag: tag) ??
    _ensurePostSharersController(
      postID: postID,
      tag: tag,
      permanent: permanent,
    );

PostSharersController? maybeFindPostSharersController({String? tag}) =>
    _maybeFindPostSharersController(tag: tag);
