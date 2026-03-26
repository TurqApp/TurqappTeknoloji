part of 'post_sharers_controller.dart';

class PostSharersController extends GetxController {
  static const int _pageSize = 20;

  static PostSharersController ensure({
    required String postID,
    String? tag,
    bool permanent = false,
  }) =>
      _ensurePostSharersController(
        postID: postID,
        tag: tag,
        permanent: permanent,
      );

  static PostSharersController? maybeFind({String? tag}) =>
      _maybeFindPostSharersController(tag: tag);

  final _PostSharersControllerState _state;

  PostSharersController({required String postID})
      : _state = _PostSharersControllerState(postID: postID);

  @override
  void onInit() {
    super.onInit();
    _handlePostSharersOnInit();
  }

  @override
  void onClose() {
    _handlePostSharersOnClose();
    super.onClose();
  }
}
