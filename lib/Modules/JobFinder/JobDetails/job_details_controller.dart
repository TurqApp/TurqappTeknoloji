import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../JobCreator/job_creator.dart';
import '../ApplicationReview/application_review.dart';

class JobDetailsController extends GetxController {
  final Rx<JobModel> model;
  final saved = false.obs;
  final basvuruldu = false.obs;
  final cvVar = false.obs;
  final nickname = ''.obs;
  final avatarUrl = kDefaultAvatarUrl.obs;
  final fullname = ''.obs;
  final RxList<JobModel> list = <JobModel>[].obs;

  JobDetailsController({required JobModel model}) : model = model.obs;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    await cvCheck();
    await getUserData(model.value.userID);
    await checkSaved(model.value.docID);
    await checkBasvuru(model.value.docID);
    await getSimilar(model.value.meslek);
    _incrementViewCount();
  }

  Future<void> _incrementViewCount() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      if (model.value.userID == uid) return;
      await FirebaseFirestore.instance
          .collection(JobCollection.name)
          .doc(model.value.docID)
          .update({'viewCount': FieldValue.increment(1)});
    } catch (_) {}
  }

  Future<void> getUserData(String userID) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get();

      if (!snap.exists || snap.data() == null) {
        avatarUrl.value = kDefaultAvatarUrl;
        return;
      }
      final data = snap.data()!;

      fullname.value = '${data['firstName'] ?? ''} '
          '${data['lastName'] ?? ''}';
      nickname.value =
          (data['nickname'] ?? data['username'] ?? data['displayName'] ?? '')
              .toString();
      final profile = (data['profile'] is Map<String, dynamic>)
          ? data['profile'] as Map<String, dynamic>
          : const <String, dynamic>{};
      avatarUrl.value = resolveAvatarUrl(data, profile: profile);
    } catch (e) {
      print('getUserData hatası: $e');
      avatarUrl.value = kDefaultAvatarUrl;
    }
  }

  Future<void> cvCheck() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('CV')
          .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
          .get();
      cvVar.value = snap.exists;
    } catch (e) {
      print('cvCheck hatası: $e');
    }
  }

  Future<void> checkSaved(String docId) async {
    try {
      final uid = (FirebaseAuth.instance.currentUser?.uid ?? '');
      if (uid.isEmpty) {
        saved.value = false;
        return;
      }
      final savedDocId = '${uid}_$docId';
      final snap = await FirebaseFirestore.instance
          .collection('SavedIsBul')
          .doc(savedDocId)
          .get();
      saved.value = snap.exists;
    } catch (e) {
      print('checkSaved hatası: $e');
      saved.value = false;
    }
  }

  Future<void> toggleSave(String docId) async {
    final uid = (FirebaseAuth.instance.currentUser?.uid ?? '');
    if (uid.isEmpty) {
      AppSnackbar('Hata', 'Lütfen tekrar giriş yapın.');
      return;
    }
    final savedDocId = '${uid}_$docId';
    final userSavedRef = FirebaseFirestore.instance
        .collection('SavedIsBul')
        .doc(savedDocId);

    try {
      final snap = await userSavedRef.get();

      if (snap.exists) {
        await userSavedRef.delete();
        saved.value = false;
      } else {
        final ts = {
          'timeStamp': DateTime.now().millisecondsSinceEpoch,
          'userID': uid,
          'jobID': docId,
        };
        await userSavedRef.set(ts);
        saved.value = true;
      }
    } catch (e) {
      print('toggleSave hatası: $e');
      AppSnackbar('Hata', 'Kaydetme işlemi başarısız.');
    }
  }

  Future<void> shareJob() async {
    final current = model.value;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final canShare =
        AdminAccessService.isKnownAdminSync() || uid == current.userID;
    if (!canShare) {
      AppSnackbar("Yetki", "Sadece admin ve ilan sahibi paylaşabilir.");
      return;
    }
    await ShareActionGuard.run(() async {
      var shortUrl = '';
      try {
        shortUrl = await ShortLinkService().getJobPublicUrl(
          jobId: current.docID,
          title: current.ilanBasligi.isNotEmpty
              ? current.ilanBasligi
              : current.meslek,
          desc: current.about.isNotEmpty ? current.about : current.isTanimi,
          imageUrl: current.logo,
        );
      } catch (_) {}

      if (shortUrl.trim().isEmpty) {
        shortUrl = 'https://turqapp.com/i/job:${current.docID}';
      }

      final title =
          current.ilanBasligi.isNotEmpty ? current.ilanBasligi : current.meslek;
      await ShareLinkService.shareUrl(
        url: shortUrl,
        title: title,
        subject: title,
      );
    });
  }

  Future<void> getSimilar(String meslek) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(JobCollection.name)
          .where('meslek', isEqualTo: meslek)
          .where('ended', isEqualTo: false)
          .limit(15)
          .get();

      final jobs =
          snapshot.docs.map((d) => JobModel.fromMap(d.data(), d.id)).toList();
      list.assignAll(jobs);
    } catch (e) {
      print('getSimilar hatası: $e');
    }
  }

  Future<void> showMapsSheet(double lat, double long) async {
    Get.bottomSheet(
      barrierColor: Colors.black.withAlpha(50),
      SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Haritalarda Aç',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'MontserratBold',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _mapTile(
                icon: 'assets/icons/googlemaps.webp',
                text: 'Google Haritalar\'da Aç',
                onTap: () async {
                  final url = Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=$lat,$long');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                  Get.back();
                },
              ),
              if (Platform.isIOS)
                _mapTile(
                  icon: 'assets/icons/applemaps.webp',
                  text: 'Apple Haritalar\'da Aç',
                  onTap: () async {
                    final url =
                        Uri.parse('http://maps.apple.com/?q=$lat,$long');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                    Get.back();
                  },
                ),
              _mapTile(
                icon: 'assets/icons/yandexmaps.webp',
                text: 'Yandex Haritalar\'da Aç',
                onTap: () async {
                  final appUrl = Uri.parse(
                      'yandexmaps://maps.yandex.ru/?ll=$long,$lat&z=10');
                  if (await canLaunchUrl(appUrl)) {
                    await launchUrl(appUrl,
                        mode: LaunchMode.externalApplication);
                  } else {
                    final webUrl = Uri.parse(
                        'https://yandex.com/maps/?ll=$long,$lat&z=10');
                    if (await canLaunchUrl(webUrl)) {
                      await launchUrl(webUrl,
                          mode: LaunchMode.externalApplication);
                    }
                  }
                  Get.back();
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _mapTile({
    required String icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: Image.asset(icon),
            ),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(fontFamily: 'MontserratBold')),
          ],
        ),
      ),
    );
  }

  Future<void> checkBasvuru(String docID) async {
    try {
      final uid = (FirebaseAuth.instance.currentUser?.uid ?? '');
      final snap = await FirebaseFirestore.instance
          .collection(JobCollection.name)
          .doc(docID)
          .collection('Applications')
          .doc(uid)
          .get();
      basvuruldu.value = snap.exists;
    } catch (e) {
      print('checkBasvuru hatası: $e');
      basvuruldu.value = false;
    }
  }

  /// Dual-write başvuru toggle with batch
  Future<void> toggleBasvuru(String docId) async {
    final uid = (FirebaseAuth.instance.currentUser?.uid ?? '');
    if (uid.isEmpty) {
      AppSnackbar('Hata', 'Başvuru için tekrar giriş yapın.');
      return;
    }
    final jobRef = FirebaseFirestore.instance
        .collection(JobCollection.name)
        .doc(docId)
        .collection('Applications')
        .doc(uid);
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('myApplications')
        .doc(docId);
    final ownerNotificationRef = FirebaseFirestore.instance
        .collection('users')
        .doc(model.value.userID)
        .collection('notifications')
        .doc();
    final jobDocRef =
        FirebaseFirestore.instance.collection(JobCollection.name).doc(docId);

    try {
      final snap = await jobRef.get();
      final batch = FirebaseFirestore.instance.batch();

      if (snap.exists) {
        // Cancel application
        batch.delete(jobRef);
        batch.delete(userRef);
        batch.update(jobDocRef, {'applicationCount': FieldValue.increment(-1)});
        await batch.commit();

        // Prevent negative count
        final jobSnap = await jobDocRef.get();
        if (jobSnap.exists) {
          final count = (jobSnap.data()?['applicationCount'] ?? 0) as num;
          if (count < 0) {
            await jobDocRef.update({'applicationCount': 0});
          }
        }

        basvuruldu.value = false;
      } else {
        final now = DateTime.now().millisecondsSinceEpoch;
        final job = model.value;
        final title = job.ilanBasligi.isNotEmpty ? job.ilanBasligi : job.meslek;
        final currentUserDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final currentUserData = currentUserDoc.data() ?? const {};
        final applicantName = [
          (currentUserData['firstName'] ?? '').toString().trim(),
          (currentUserData['lastName'] ?? '').toString().trim(),
        ].where((e) => e.isNotEmpty).join(' ').trim();
        final applicantLabel = applicantName.isNotEmpty
            ? applicantName
            : (currentUserData['nickname'] ??
                    currentUserData['username'] ??
                    currentUserData['displayName'] ??
                    'Bir kullanıcı')
                .toString();
        final applicantImage =
            (currentUserData['avatarUrl'] ?? currentUserData['avatarUrl'] ?? '')
                .toString();

        batch.set(jobRef, {
          'timeStamp': now,
          'status': 'pending',
          'statusUpdatedAt': now,
          'note': '',
          'jobTitle': title,
          'companyName': job.brand,
          'companyLogo': job.logo,
          'applicantName': applicantName,
          'applicantNickname': (currentUserData['nickname'] ??
                  currentUserData['username'] ??
                  currentUserData['displayName'] ??
                  '')
              .toString()
              .trim(),
          'applicantPfImage': applicantImage,
          'userID': uid,
        });

        batch.set(userRef, {
          'timeStamp': now,
          'jobTitle': title,
          'companyName': job.brand,
          'companyLogo': job.logo,
          'status': 'pending',
          'userID': uid,
          'applicantName': applicantName,
          'applicantNickname': (currentUserData['nickname'] ??
                  currentUserData['username'] ??
                  currentUserData['displayName'] ??
                  '')
              .toString()
              .trim(),
          'applicantPfImage': applicantImage,
        });

        batch.update(jobDocRef, {
          'applicationCount': FieldValue.increment(1),
        });
        batch.set(ownerNotificationRef, {
          'type': 'job_application',
          'fromUserID': uid,
          'postID': docId,
          'timeStamp': now,
          'read': false,
          'title': applicantLabel,
          'body': '$title ilanina basvuru yapti',
          'thumbnail': applicantImage,
        });

        await batch.commit();
        basvuruldu.value = true;
        AppSnackbar('Başarılı', 'Başvurun gönderildi.');
      }
    } catch (e) {
      print('toggleBasvuru hatası: $e');
      AppSnackbar('Hata', 'Başvuru sırasında bir sorun oluştu.');
    }
  }

  Future<void> goToEdit() async {
    final result =
        await Get.to<JobModel?>(JobCreator(existingJob: model.value));
    if (result != null) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection(JobCollection.name)
            .doc(model.value.docID)
            .get();

        if (snap.exists && snap.data() != null) {
          model.value = JobModel.fromMap(snap.data()!, snap.id);
        }
      } catch (e) {
        print('goToEdit hatası: $e');
      }
    }
  }

  void goToApplicationReview() {
    final job = model.value;
    Get.to(() => ApplicationReview(
          jobDocID: job.docID,
          jobTitle: job.ilanBasligi.isNotEmpty ? job.ilanBasligi : job.meslek,
        ));
  }

  Future<void> unpublishAd() async {
    final docId = model.value.docID;
    final ref =
        FirebaseFirestore.instance.collection(JobCollection.name).doc(docId);
    final snap = await ref.get();

    if (!snap.exists) throw Exception('İlan bulunamadı');

    await ref.update({
      'ended': true,
      'endedAt': DateTime.now().millisecondsSinceEpoch,
    });

    final refreshed = await ref.get();
    if (refreshed.exists && refreshed.data() != null) {
      model.value = JobModel.fromMap(refreshed.data()!, refreshed.id);
    }
  }
}
