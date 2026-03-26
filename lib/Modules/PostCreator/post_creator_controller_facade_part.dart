part of 'post_creator_controller.dart';

void _handlePostCreatorControllerInit(PostCreatorController controller) {
  _PostCreatorControllerLifecyclePart(controller).handleOnInit();
}

void _handlePostCreatorControllerClose(PostCreatorController controller) {
  _PostCreatorControllerLifecyclePart(controller).handleOnClose();
}

void _handlePostCreatorControllerMetrics(PostCreatorController controller) {
  _PostCreatorControllerLifecyclePart(controller).handleDidChangeMetrics();
}
