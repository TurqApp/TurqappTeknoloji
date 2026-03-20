import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class JobContentController extends GetxController {
  final JobRepository _jobRepository = JobRepository.ensure();
  var saved = false.obs;
  final Map<String, Future<JobModel?>> _jobFutureCache = <String, Future<JobModel?>>{};

  Future<JobModel?> resolveFreshJob(JobModel model) {
    final docId = model.docID.trim();
    if (docId.isEmpty) return Future<JobModel?>.value(model);
    return _jobFutureCache.putIfAbsent(
      docId,
      () => _jobRepository.fetchById(
        docId,
        preferCache: true,
        forceRefresh: true,
      ),
    );
  }

  Future<void> checkSaved(String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      saved.value = await JobSavedStore.isSaved(uid, docId);
    } catch (_) {
      saved.value = false;
    }
  }

  Future<void> toggleSave(String docId) async {
    if (!UserModerationGuard.ensureAllowed(RestrictedAction.saveJob)) {
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final isAlreadySaved = await JobSavedStore.isSaved(uid, docId);
      if (isAlreadySaved) {
        await JobSavedStore.unsave(uid, docId);
        saved.value = false;
      } else {
        await JobSavedStore.save(uid, docId);
        saved.value = true;
      }
    } catch (_) {}
  }

  Future<void> reactivateEndedJob(JobModel model) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
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

    if (Get.isRegistered<MyJobAdsController>()) {
      await Get.find<MyJobAdsController>().getActive();
    }
    if (Get.isRegistered<JobFinderController>()) {
      final finder = Get.find<JobFinderController>();
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
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
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
