part of 'booklet_result_preview_controller.dart';

class BookletResultPreviewController extends GetxController {
  static BookletResultPreviewController ensure(
    BookletResultModel model, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      BookletResultPreviewController(model),
      tag: tag,
      permanent: permanent,
    );
  }

  static BookletResultPreviewController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<BookletResultPreviewController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<BookletResultPreviewController>(tag: tag);
  }

  final BookletResultModel model;
  final _state = _BookletResultPreviewControllerState();

  BookletResultPreviewController(this.model) {
    _handleBookletResultPreviewInit(this);
  }
}
