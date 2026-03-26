part of 'booklet_preview_controller.dart';

class BookletPreviewController extends GetxController {
  static BookletPreviewController ensure(
    BookletModel model, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      BookletPreviewController(model),
      tag: tag,
      permanent: permanent,
    );
  }

  static BookletPreviewController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<BookletPreviewController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<BookletPreviewController>(tag: tag);
  }

  final _BookletPreviewControllerState _state;

  BookletPreviewController(BookletModel model)
      : _state = _BookletPreviewControllerState(model: model);

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }
}
