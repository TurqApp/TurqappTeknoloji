part of 'booklet_result_content_controller.dart';

BookletResultContentController ensureBookletResultContentController(
  BookletResultModel model, {
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindBookletResultContentController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    BookletResultContentController(model),
    tag: tag,
    permanent: permanent,
  );
}

BookletResultContentController? maybeFindBookletResultContentController({
  String? tag,
}) {
  final isRegistered = Get.isRegistered<BookletResultContentController>(
    tag: tag,
  );
  if (!isRegistered) return null;
  return Get.find<BookletResultContentController>(tag: tag);
}
