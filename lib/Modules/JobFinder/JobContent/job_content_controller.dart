import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Modules/JobFinder/MyJobAds/my_job_ads_controller.dart';
import 'package:turqappv2/Modules/JobFinder/job_finder_controller.dart';

class JobContentController extends GetxController {
  var saved = false.obs;

  Future<void> checkSaved(String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("SavedIsBul")
          .doc(docId)
          .get();
      saved.value = doc.exists;
    } catch (e) {
      print("checkSaved hatası: $e");
      saved.value = false;
    }
  }

  Future<void> toggleSave(String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("SavedIsBul")
        .doc(docId);

    try {
      final doc = await ref.get();

      if (doc.exists) {
        await ref.delete();
        saved.value = false;
      } else {
        final ts = {"timeStamp": DateTime.now().millisecondsSinceEpoch};
        await ref.set(ts);
        saved.value = true;
      }
    } catch (e) {
      print("toggleSave hatası: $e");
    }
  }

  Future<void> reactivateEndedJob(JobModel model) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (model.userID != uid || !model.ended) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final ref = FirebaseFirestore.instance
        .collection(JobCollection.name)
        .doc(model.docID);
    final snap = await ref.get();

    if (!snap.exists) {
      Get.snackbar("Uyarı", "İlan bulunamadı.");
      return;
    }

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
    Get.snackbar("Yenilendi", "İlan tekrar yayına alındı.");
  }

  Future<void> shareJob(JobModel model) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final canShare =
        AdminAccessService.isKnownAdminSync() || uid == model.userID;
    if (!canShare) {
      AppSnackbar("Yetki", "Sadece admin ve ilan sahibi paylaşabilir.");
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
