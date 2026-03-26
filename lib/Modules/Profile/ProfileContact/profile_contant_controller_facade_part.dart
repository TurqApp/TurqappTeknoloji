part of 'profile_contant_controller.dart';

ProfileContactController ensureProfileContactController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindProfileContactController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    ProfileContactController(),
    tag: tag,
    permanent: permanent,
  );
}

ProfileContactController? maybeFindProfileContactController({String? tag}) {
  final isRegistered = Get.isRegistered<ProfileContactController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<ProfileContactController>(tag: tag);
}

extension ProfileContactControllerFacadePart on ProfileContactController {
  Future<void> toggleEmailVisibility() => _toggleProfileEmailVisibility(this);

  Future<void> toggleCallVisibility() => _toggleProfileCallVisibility(this);
}
