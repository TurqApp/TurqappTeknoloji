part of 'rozet_content.dart';

RozetController ensureRozetController(
  String userID, {
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindRozetController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    RozetController(userID),
    tag: tag,
    permanent: permanent,
  );
}

RozetController? maybeFindRozetController({String? tag}) {
  final isRegistered = Get.isRegistered<RozetController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<RozetController>(tag: tag);
}
