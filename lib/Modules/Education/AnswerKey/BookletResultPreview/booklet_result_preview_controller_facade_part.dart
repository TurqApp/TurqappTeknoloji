part of 'booklet_result_preview_controller.dart';

BookletResultPreviewController ensureBookletResultPreviewController(
  BookletResultModel model, {
  String? tag,
  bool permanent = false,
}) =>
    maybeFindBookletResultPreviewController(tag: tag) ??
    Get.put(
      BookletResultPreviewController(model),
      tag: tag,
      permanent: permanent,
    );

BookletResultPreviewController? maybeFindBookletResultPreviewController({
  String? tag,
}) =>
    Get.isRegistered<BookletResultPreviewController>(tag: tag)
        ? Get.find<BookletResultPreviewController>(tag: tag)
        : null;
