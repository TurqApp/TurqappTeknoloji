part of 'search_answer_key_controller.dart';

SearchAnswerKeyController ensureSearchAnswerKeyController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindSearchAnswerKeyController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    SearchAnswerKeyController(),
    tag: tag,
    permanent: permanent,
  );
}

SearchAnswerKeyController? maybeFindSearchAnswerKeyController({String? tag}) {
  final isRegistered = Get.isRegistered<SearchAnswerKeyController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<SearchAnswerKeyController>(tag: tag);
}

extension SearchAnswerKeyControllerFacadePart on SearchAnswerKeyController {
  void resetSearch() => _resetSearchState();

  void navigateToPreview(BookletModel model) {
    Get.to(() => BookletPreview(model: model));
  }
}
