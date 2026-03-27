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
