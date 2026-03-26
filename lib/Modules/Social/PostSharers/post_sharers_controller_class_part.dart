part of 'post_sharers_controller.dart';

class PostSharersController extends GetxController {
  static const int _pageSize = 20;

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
