part of 'booklet_preview_controller.dart';

extension BookletPreviewControllerFacadePart on BookletPreviewController {
  void _initialize() => BookletPreviewControllerRuntimePart(this).initialize();

  Future<void> _loadBookmarkState(String currentUserId) =>
      BookletPreviewControllerRuntimePart(this)
          .loadBookmarkState(currentUserId);

  Future<void> fetchAnswerKeys() =>
      BookletPreviewControllerRuntimePart(this).fetchAnswerKeys();

  Future<void> fetchUserData() =>
      BookletPreviewControllerRuntimePart(this).fetchUserData();

  Future<void> toggleBookmark() =>
      BookletPreviewControllerRuntimePart(this).toggleBookmark();

  void navigateToAnswerKey(BuildContext context, AnswerKeySubModel subModel) {
    Get.to(() => BookletAnswer(model: subModel, anaModel: model));
  }
}
