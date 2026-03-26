part of 'follower_controller.dart';

FollowerController ensureFollowerController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindFollowerController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    FollowerController(),
    tag: tag,
    permanent: permanent,
  );
}

FollowerController? maybeFindFollowerController({String? tag}) {
  final isRegistered = Get.isRegistered<FollowerController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<FollowerController>(tag: tag);
}

extension FollowerControllerFacadePart on FollowerController {
  Future<void> getData(String userID) =>
      _FollowerControllerCacheX(this).getData(userID);

  Future<void> followControl(String userID) =>
      _FollowerControllerCacheX(this).followControl(userID);
}
