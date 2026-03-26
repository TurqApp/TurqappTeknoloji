part of 'tutoring_search_controller.dart';

TutoringSearchController ensureTutoringSearchController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindTutoringSearchController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    TutoringSearchController(),
    tag: tag,
    permanent: permanent,
  );
}

TutoringSearchController? maybeFindTutoringSearchController({String? tag}) {
  final isRegistered = Get.isRegistered<TutoringSearchController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<TutoringSearchController>(tag: tag);
}

extension TutoringSearchControllerFacadePart on TutoringSearchController {
  void resetSearch() => _handleResetSearch();
}
