part of 'share_grid_controller.dart';

abstract class _ShareGridControllerBase extends GetxController {
  _ShareGridControllerBase({
    required String postType,
    required String postID,
  }) : _state = _ShareGridControllerState(
          postType: postType,
          postID: postID,
        );

  final _ShareGridControllerState _state;
}
