part of 'category_based_answer_key_controller_library.dart';

CategoryBasedAnswerKeyController ensureCategoryBasedAnswerKeyController(
  String sinavTuru, {
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindCategoryBasedAnswerKeyController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    CategoryBasedAnswerKeyController(sinavTuru),
    tag: tag,
    permanent: permanent,
  );
}

CategoryBasedAnswerKeyController? maybeFindCategoryBasedAnswerKeyController({
  String? tag,
}) {
  final isRegistered =
      Get.isRegistered<CategoryBasedAnswerKeyController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<CategoryBasedAnswerKeyController>(tag: tag);
}
