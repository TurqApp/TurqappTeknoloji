part of 'optical_form_entry_controller_library.dart';

OpticalFormEntryController ensureOpticalFormEntryController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindOpticalFormEntryController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    OpticalFormEntryController(),
    tag: tag,
    permanent: permanent,
  );
}

OpticalFormEntryController? maybeFindOpticalFormEntryController({
  String? tag,
}) {
  final isRegistered = Get.isRegistered<OpticalFormEntryController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<OpticalFormEntryController>(tag: tag);
}
