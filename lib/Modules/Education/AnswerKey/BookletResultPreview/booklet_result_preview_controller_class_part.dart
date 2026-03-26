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
  final anaModel = Rx<BookletModel?>(null);
  final BookletRepository _bookletRepository = BookletRepository.ensure();

  BookletResultPreviewController(this.model) {
    getData();
  }

  Future<void> getData() async {
    anaModel.value = await _bookletRepository.fetchById(
      model.kitapcikID,
      preferCache: true,
    );
  }
}
