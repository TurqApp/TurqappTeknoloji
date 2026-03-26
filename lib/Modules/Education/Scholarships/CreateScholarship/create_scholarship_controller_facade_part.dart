part of 'create_scholarship_controller.dart';

CreateScholarshipController _ensureCreateScholarshipController({
  required String tag,
  bool permanent = false,
}) {
  final existing = _maybeFindCreateScholarshipController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    CreateScholarshipController(),
    tag: tag,
    permanent: permanent,
  );
}

CreateScholarshipController? _maybeFindCreateScholarshipController({
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
