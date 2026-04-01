part of 'recommended_user_content_controller.dart';

RecommendedUserContentController ensureRecommendedUserContentController({
  required String userID,
  String? tag,
  bool permanent = false,
}) =>
    _ensureRecommendedUserContentController(
      userID: userID,
      tag: tag,
      permanent: permanent,
    );

RecommendedUserContentController? maybeFindRecommendedUserContentController({
  String? tag,
}) =>
    _maybeFindRecommendedUserContentController(tag: tag);

RecommendedUserContentController _ensureRecommendedUserContentController({
  required String userID,
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindRecommendedUserContentController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    RecommendedUserContentController(userID: userID),
    tag: tag,
    permanent: permanent,
  );
}

RecommendedUserContentController? _maybeFindRecommendedUserContentController({
  String? tag,
}) {
  final isRegistered =
      Get.isRegistered<RecommendedUserContentController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<RecommendedUserContentController>(tag: tag);
}
