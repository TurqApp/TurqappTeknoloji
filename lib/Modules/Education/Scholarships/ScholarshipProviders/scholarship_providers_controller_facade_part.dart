part of 'scholarship_providers_controller.dart';

ScholarshipProvidersController ensureScholarshipProvidersController({
  required String tag,
  bool permanent = false,
}) {
  final existing = maybeFindScholarshipProvidersController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    ScholarshipProvidersController(),
    tag: tag,
    permanent: permanent,
  );
}

ScholarshipProvidersController? maybeFindScholarshipProvidersController({
  required String tag,
}) {
  final isRegistered =
      Get.isRegistered<ScholarshipProvidersController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<ScholarshipProvidersController>(tag: tag);
}

extension ScholarshipProvidersControllerFacadePart
    on ScholarshipProvidersController {
  Future<void> fetchProviders({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _fetchProvidersImpl(
        silent: silent,
        forceRefresh: forceRefresh,
      );
}
