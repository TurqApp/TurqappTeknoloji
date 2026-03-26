part of 'job_content_controller.dart';

class JobContentController extends GetxController {
  static JobContentController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      JobContentController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static JobContentController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<JobContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<JobContentController>(tag: tag);
  }

  final JobRepository _jobRepository = JobRepository.ensure();
  static final Map<String, Set<String>> _savedIdsByUser =
      <String, Set<String>>{};
  static final Map<String, Future<Set<String>>> _savedIdsLoaders =
      <String, Future<Set<String>>>{};
  var saved = false.obs;
  String _initializedSavedDocId = '';

  static Future<void> warmSavedIdsForCurrentUser() =>
      _warmSavedIdsForCurrentUserImpl();

  Future<void> primeSavedState(String docId) => _primeSavedStateImpl(docId);

  Future<void> toggleSave(String docId) => _toggleSaveImpl(docId);

  Future<void> reactivateEndedJob(JobModel model) =>
      _reactivateEndedJobImpl(model);

  Future<void> shareJob(JobModel model) => _shareJobImpl(model);
}
