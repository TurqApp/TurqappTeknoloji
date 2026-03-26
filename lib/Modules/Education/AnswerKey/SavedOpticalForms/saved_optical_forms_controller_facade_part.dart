part of 'saved_optical_forms_controller_library.dart';

SavedOpticalFormsController ensureSavedOpticalFormsController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindSavedOpticalFormsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    SavedOpticalFormsController(),
    tag: tag,
    permanent: permanent,
  );
}

SavedOpticalFormsController? maybeFindSavedOpticalFormsController({
  String? tag,
}) {
  final isRegistered = Get.isRegistered<SavedOpticalFormsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<SavedOpticalFormsController>(tag: tag);
}

extension SavedOpticalFormsControllerFacadePart on SavedOpticalFormsController {
  bool _sameBookletEntries(
    List<BookletModel> current,
    List<BookletModel> next,
  ) =>
      SavedOpticalFormsControllerRuntimePart(this).sameBookletEntries(
        current,
        next,
      );

  Future<void> _bootstrapData() =>
      SavedOpticalFormsControllerRuntimePart(this).bootstrapData();

  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      SavedOpticalFormsControllerRuntimePart(this).getData(
        silent: silent,
        forceRefresh: forceRefresh,
      );
}
