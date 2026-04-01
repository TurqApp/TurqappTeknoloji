part of 'saved_tutorings_controller.dart';

SavedTutoringsController ensureSavedTutoringsController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindSavedTutoringsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    SavedTutoringsController(),
    tag: tag,
    permanent: permanent,
  );
}

SavedTutoringsController? maybeFindSavedTutoringsController({String? tag}) {
  final isRegistered = Get.isRegistered<SavedTutoringsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<SavedTutoringsController>(tag: tag);
}

extension SavedTutoringsControllerFacadePart on SavedTutoringsController {
  Future<void> loadSavedTutorings() => _loadSavedTutorings(this);

  Future<void> addSavedTutoring(String docId) => _addSavedTutoring(this, docId);

  Future<void> removeSavedTutoring(String docId) =>
      _removeSavedTutoring(this, docId);
}
