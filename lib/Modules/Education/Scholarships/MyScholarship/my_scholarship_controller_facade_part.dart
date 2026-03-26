part of 'my_scholarship_controller_library.dart';

MyScholarshipController ensureMyScholarshipController({
  required String tag,
  bool permanent = false,
}) {
  final existing = maybeFindMyScholarshipController(tag: tag);
  if (existing != null) return existing;
  return Get.put(MyScholarshipController(), tag: tag, permanent: permanent);
}

MyScholarshipController? maybeFindMyScholarshipController({
  required String tag,
}) {
  final isRegistered = Get.isRegistered<MyScholarshipController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<MyScholarshipController>(tag: tag);
}

extension MyScholarshipControllerFacadePart on MyScholarshipController {
  Future<void> bootstrapMyScholarships() =>
      MyScholarshipControllerRuntimePart(this).bootstrapMyScholarships();

  Future<void> fetchMyScholarships({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      MyScholarshipControllerRuntimePart(this).fetchMyScholarships(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  Future<List<Map<String, dynamic>>> buildScholarshipCards(
    List<Map<String, dynamic>> rawScholarships, {
    bool userCacheOnly = false,
  }) =>
      MyScholarshipControllerRuntimePart(this).buildScholarshipCards(
        rawScholarships,
        userCacheOnly: userCacheOnly,
      );
}
