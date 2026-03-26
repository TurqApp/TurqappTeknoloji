part of 'scholarship_repository.dart';

ScholarshipRepository? _maybeFindScholarshipRepository() =>
    Get.isRegistered<ScholarshipRepository>()
        ? Get.find<ScholarshipRepository>()
        : null;

ScholarshipRepository _ensureScholarshipRepository() =>
    _maybeFindScholarshipRepository() ??
    Get.put(ScholarshipRepository(), permanent: true);

void _handleScholarshipRepositoryInit(ScholarshipRepository repository) {
  SharedPreferences.getInstance().then((prefs) => repository._prefs = prefs);
}
