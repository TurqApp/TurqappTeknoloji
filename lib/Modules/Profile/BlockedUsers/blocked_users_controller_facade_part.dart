part of 'blocked_users_controller.dart';

BlockedUsersController ensureBlockedUsersController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindBlockedUsersController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    BlockedUsersController(),
    tag: tag,
    permanent: permanent,
  );
}

BlockedUsersController? maybeFindBlockedUsersController({String? tag}) {
  final isRegistered = Get.isRegistered<BlockedUsersController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<BlockedUsersController>(tag: tag);
}
