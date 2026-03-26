part of 'booklet_preview_controller.dart';

BookletPreviewController ensureBookletPreviewController(
  BookletModel model, {
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindBookletPreviewController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    BookletPreviewController(model),
    tag: tag,
    permanent: permanent,
  );
}

BookletPreviewController? maybeFindBookletPreviewController({String? tag}) {
  final isRegistered = Get.isRegistered<BookletPreviewController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<BookletPreviewController>(tag: tag);
}

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
