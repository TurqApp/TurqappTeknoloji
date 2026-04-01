part of 'antreman_comments_controller.dart';

extension AntremanCommentsControllerRuntimePart on AntremanCommentsController {
  void _handleCommentsInit() {
    unawaited(fetchComments());
    commentController.addListener(() {
      isTextFieldNotEmpty.value = commentController.text.isNotEmpty;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    scrollController.addListener(() {
      if (scrollController.offset <= 0 &&
          scrollController.position.userScrollDirection ==
              ScrollDirection.reverse) {
        Get.back();
      }
    });
  }

  void _handleCommentsClose() {
    commentController.dispose();
    focusNode.dispose();
    scrollController.dispose();
  }
}
