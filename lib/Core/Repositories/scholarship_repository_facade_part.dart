part of 'scholarship_repository.dart';

ScholarshipRepository? maybeFindScholarshipRepository() =>
    _maybeFindScholarshipRepository();

ScholarshipRepository ensureScholarshipRepository() =>
    _ensureScholarshipRepository();

ScholarshipRepository? _maybeFindScholarshipRepository() =>
    Get.isRegistered<ScholarshipRepository>()
        ? Get.find<ScholarshipRepository>()
        : null;

ScholarshipRepository _ensureScholarshipRepository() =>
    _maybeFindScholarshipRepository() ??
    Get.put(ScholarshipRepository(), permanent: true);

void _handleScholarshipRepositoryInit(ScholarshipRepository repository) {
  ensureLocalPreferenceRepository()
      .sharedPreferences()
      .then((prefs) => repository._prefs = prefs);
}
