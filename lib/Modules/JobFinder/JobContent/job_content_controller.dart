import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/job_saved_store.dart';
import 'package:turqappv2/Core/Services/user_moderation_guard.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Modules/JobFinder/MyJobAds/my_job_ads_controller.dart';
import 'package:turqappv2/Modules/JobFinder/job_finder_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'job_content_controller_actions_part.dart';

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

  Future<Set<String>> _loadSavedIds(String uid) {
    final cached = JobContentController._savedIdsByUser[uid];
    if (cached != null) return Future<Set<String>>.value(cached);
    return JobContentController._savedIdsLoaders.putIfAbsent(uid, () async {
      try {
        final records = await JobSavedStore.getSavedJobs(
          uid,
          preferCache: true,
        );
        final ids = records.map((record) => record.jobId).toSet();
        JobContentController._savedIdsByUser[uid] = ids;
        return ids;
      } finally {
        JobContentController._savedIdsLoaders.remove(uid);
      }
    });
  }

  static Future<void> warmSavedIdsForCurrentUser() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    final cached = _savedIdsByUser[uid];
    if (cached != null) return;
    final records = await JobSavedStore.getSavedJobs(
      uid,
      preferCache: true,
    );
    _savedIdsByUser[uid] = records.map((record) => record.jobId).toSet();
  }

  Future<void> primeSavedState(String docId) => _primeSavedStateImpl(docId);

  Future<void> _primeSavedStateImpl(String docId) async {
    final normalizedDocId = docId.trim();
    if (normalizedDocId.isEmpty || _initializedSavedDocId == normalizedDocId) {
      return;
    }
    _initializedSavedDocId = normalizedDocId;
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      final savedIds = await _loadSavedIds(uid);
      saved.value = savedIds.contains(normalizedDocId);
    } catch (_) {
      saved.value = false;
    }
  }

  Future<void> toggleSave(String docId) => _toggleSaveImpl(docId);

  Future<void> _toggleSaveImpl(String docId) async {
    if (!UserModerationGuard.ensureAllowed(RestrictedAction.saveJob)) {
      return;
    }
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;

    try {
      final savedIds = await _loadSavedIds(uid);
      final isAlreadySaved = savedIds.contains(docId);
      if (isAlreadySaved) {
        await JobSavedStore.unsave(uid, docId);
        savedIds.remove(docId);
        saved.value = false;
      } else {
        await JobSavedStore.save(uid, docId);
        savedIds.add(docId);
        saved.value = true;
      }
    } catch (_) {}
  }

  Future<void> reactivateEndedJob(JobModel model) =>
      _reactivateEndedJobImpl(model);

  Future<void> shareJob(JobModel model) => _shareJobImpl(model);
}
