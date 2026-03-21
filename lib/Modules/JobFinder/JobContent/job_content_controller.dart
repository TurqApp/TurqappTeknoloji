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
    if (!Get.isRegistered<JobContentController>(tag: tag)) return null;
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
    final cached = _savedIdsByUser[uid];
    if (cached != null) return Future<Set<String>>.value(cached);
    return _savedIdsLoaders.putIfAbsent(uid, () async {
      try {
        final records = await JobSavedStore.getSavedJobs(
          uid,
          preferCache: true,
        );
        final ids = records.map((record) => record.jobId).toSet();
        _savedIdsByUser[uid] = ids;
        return ids;
      } finally {
        _savedIdsLoaders.remove(uid);
      }
    });
  }

  static Future<void> warmSavedIdsForCurrentUser() async {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty) return;
    final cached = _savedIdsByUser[uid];
    if (cached != null) return;
    final records = await JobSavedStore.getSavedJobs(
      uid,
      preferCache: true,
    );
    _savedIdsByUser[uid] = records.map((record) => record.jobId).toSet();
  }

  Future<void> primeSavedState(String docId) async {
    final normalizedDocId = docId.trim();
    if (normalizedDocId.isEmpty || _initializedSavedDocId == normalizedDocId) {
      return;
    }
    _initializedSavedDocId = normalizedDocId;
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty) return;
    try {
      final savedIds = await _loadSavedIds(uid);
      saved.value = savedIds.contains(normalizedDocId);
    } catch (_) {
      saved.value = false;
    }
  }

  Future<void> toggleSave(String docId) async {
    if (!UserModerationGuard.ensureAllowed(RestrictedAction.saveJob)) {
      return;
    }
    final uid = CurrentUserService.instance.userId;
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

  Future<void> reactivateEndedJob(JobModel model) async {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty) return;
    if (model.userID != uid || !model.ended) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await _jobRepository.fetchById(model.docID,
        preferCache: false, forceRefresh: true);
    if (existing == null) {
      AppSnackbar(
        "common.info".tr,
        "pasaj.job_finder.listing_not_found".tr,
      );
      return;
    }

    final ref = FirebaseFirestore.instance
        .collection(JobCollection.name)
        .doc(model.docID);
    await ref.update({
      "ended": false,
      "timeStamp": now,
    });

    final myJobAdsController = MyJobAdsController.maybeFind();
    if (myJobAdsController != null) {
      await myJobAdsController.getActive();
    }
    final finder = JobFinderController.maybeFind();
    if (finder != null) {
      await finder.getStartData();
      await finder.refreshJob(model.docID);

      final idx = finder.list.indexWhere((e) => e.docID == model.docID);
      if (idx > 0) {
        final item = finder.list.removeAt(idx);
        finder.list.insert(0, item);
        finder.list.refresh();
      }
    }
    AppSnackbar(
      "common.success".tr,
      "pasaj.job_finder.reactivated".tr,
    );
  }

  Future<void> shareJob(JobModel model) async {
    final uid = CurrentUserService.instance.userId;
    final canShare =
        AdminAccessService.isKnownAdminSync() || uid == model.userID;
    if (!canShare) {
      AppSnackbar(
        "common.info".tr,
        "pasaj.job_finder.share_auth_required".tr,
      );
      return;
    }
    await ShareActionGuard.run(() async {
      var shortUrl = '';
      try {
        shortUrl = await ShortLinkService().getJobPublicUrl(
          jobId: model.docID,
          title:
              model.ilanBasligi.isNotEmpty ? model.ilanBasligi : model.meslek,
          desc: model.about.isNotEmpty ? model.about : model.isTanimi,
          imageUrl: model.logo,
        );
      } catch (_) {}

      if (shortUrl.trim().isEmpty) {
        shortUrl = 'https://turqapp.com/i/job:${model.docID}';
      }

      final title =
          model.ilanBasligi.isNotEmpty ? model.ilanBasligi : model.meslek;
      await ShareLinkService.shareUrl(
        url: shortUrl,
        title: title,
        subject: title,
      );
    });
  }
}
