part of 'my_scholarship_controller.dart';

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
