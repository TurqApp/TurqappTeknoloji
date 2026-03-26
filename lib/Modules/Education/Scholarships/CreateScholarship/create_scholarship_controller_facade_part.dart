part of 'create_scholarship_controller.dart';

CreateScholarshipController ensureCreateScholarshipController({
  required String tag,
  bool permanent = false,
}) {
  final existing = maybeFindCreateScholarshipController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    CreateScholarshipController(),
    tag: tag,
    permanent: permanent,
  );
}

CreateScholarshipController? maybeFindCreateScholarshipController({
  required String tag,
}) {
  final isRegistered = Get.isRegistered<CreateScholarshipController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<CreateScholarshipController>(tag: tag);
}

void _handleCreateScholarshipControllerInit(
  CreateScholarshipController controller,
) {
  controller.initializeFormState();
}
