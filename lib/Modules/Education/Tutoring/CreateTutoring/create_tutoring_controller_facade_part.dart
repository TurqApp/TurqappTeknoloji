part of 'create_tutoring_controller.dart';

CreateTutoringController ensureCreateTutoringController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindCreateTutoringController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    CreateTutoringController(),
    tag: tag,
    permanent: permanent,
  );
}

CreateTutoringController? maybeFindCreateTutoringController({String? tag}) {
  final isRegistered = Get.isRegistered<CreateTutoringController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<CreateTutoringController>(tag: tag);
}
