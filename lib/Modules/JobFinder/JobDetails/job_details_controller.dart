import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_action_tile.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/cv_repository.dart';
import 'package:turqappv2/Core/Repositories/job_home_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/job_saved_store.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/user_moderation_guard.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Models/job_review_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';
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
  final reviews = <JobReviewModel>[].obs;
  final reviewUsers = <String, Map<String, dynamic>>{}.obs;
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final CvRepository _cvRepository = CvRepository.ensure();
  final JobHomeSnapshotRepository _jobHomeSnapshotRepository =
      JobHomeSnapshotRepository.ensure();
  final JobRepository _jobRepository = JobRepository.ensure();
  String get _currentUserId {
    final serviceUid = CurrentUserService.instance.userId.trim();
    if (serviceUid.isNotEmpty) return serviceUid;
    return FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  }

  JobDetailsController({required JobModel model}) : model = model.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    unawaited(_refreshJob());
    unawaited(cvCheck());
    unawaited(getUserData(model.value.userID));
    unawaited(checkSaved(model.value.docID));
    unawaited(checkBasvuru(model.value.docID));
    unawaited(_bootstrapSimilar());
    unawaited(_bootstrapReviews());
    unawaited(_incrementViewCount());
  }

  Future<void> _refreshJob() async {
    try {
      final fresh = await _jobRepository.fetchById(
        model.value.docID,
        preferCache: true,
        forceRefresh: true,
      );
      if (fresh != null) {
        model.value = fresh;
      }
    } catch (_) {}
  }

  Future<void> _incrementViewCount() async {
    try {
      final uid = _currentUserId;
      if (uid.isEmpty) return;
      if (model.value.userID == uid) return;
      await _jobRepository.incrementViewCount(model.value.docID);
    } catch (_) {}
  }

  Future<void> getUserData(String userID) async {
    try {
      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (summary == null) {
        avatarUrl.value = kDefaultAvatarUrl;
        return;
      }
      fullname.value = summary.displayName;
      nickname.value = summary.nickname.isNotEmpty
          ? summary.nickname
          : summary.preferredName;
      avatarUrl.value =
          summary.avatarUrl.isNotEmpty ? summary.avatarUrl : kDefaultAvatarUrl;
    } catch (_) {
      avatarUrl.value = kDefaultAvatarUrl;
    }
  }

  Future<void> cvCheck() async {
    try {
      final uid = _currentUserId;
      if (uid.isEmpty) {
        cvVar.value = false;
        return;
      }
      final cv = await _cvRepository.getCv(uid, preferCache: true);
      cvVar.value = cv != null;
    } catch (_) {}
  }

  Future<void> checkSaved(String docId) async {
    try {
      final uid = _currentUserId;
      if (uid.isEmpty) {
        saved.value = false;
        return;
      }
      saved.value = await JobSavedStore.isSaved(uid, docId);
    } catch (_) {
      saved.value = false;
    }
  }

  Future<void> toggleSave(String docId) async {
    if (!UserModerationGuard.ensureAllowed(RestrictedAction.saveJob)) {
      return;
    }
    final uid = _currentUserId;
    if (uid.isEmpty) {
      AppSnackbar('common.error'.tr, 'pasaj.job_finder.relogin_required'.tr);
      return;
    }

    try {
      final isAlreadySaved = await JobSavedStore.isSaved(uid, docId);
      if (isAlreadySaved) {
        await JobSavedStore.unsave(uid, docId);
        saved.value = false;
      } else {
        await JobSavedStore.save(uid, docId);
        saved.value = true;
      }
    } catch (_) {
      AppSnackbar(
        'common.error'.tr,
        'pasaj.job_finder.save_failed'.tr,
      );
    }
  }

  Future<void> shareJob() async {
    final current = model.value;
    final uid = _currentUserId;
    final canShare =
        AdminAccessService.isKnownAdminSync() || uid == current.userID;
    if (!canShare) {
      AppSnackbar(
        'common.info'.tr,
        'pasaj.job_finder.share_auth_required'.tr,
      );
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
      final current = model.value;
      final query = [
        current.meslek.trim(),
        current.brand.trim(),
        current.ilanBasligi.trim(),
      ].firstWhere((value) => value.isNotEmpty, orElse: () => meslek.trim());
      if (query.isEmpty) {
        list.clear();
        return;
      }

      final result = await _jobHomeSnapshotRepository.search(
        query: query,
        userId: _currentUserId,
        limit: 20,
        forceSync: true,
      );

      final jobs = (result.data ?? const <JobModel>[])
          .where((job) => _isSimilarJob(current, job))
          .take(8)
          .toList(growable: false);
      list.assignAll(jobs);
    } catch (_) {
      list.clear();
    }
  }

  Future<void> _bootstrapSimilar() async {
    try {
      final current = model.value;
      final query = [
        current.meslek.trim(),
        current.brand.trim(),
        current.ilanBasligi.trim(),
      ].firstWhere(
        (value) => value.isNotEmpty,
        orElse: () => current.meslek.trim(),
      );
      if (query.isEmpty) return;
      final cached = await _jobHomeSnapshotRepository.search(
        query: query,
        userId: _currentUserId,
        limit: 20,
      );
      final cachedJobs = cached.data ?? const <JobModel>[];
      if (cachedJobs.isNotEmpty) {
        final jobs = cachedJobs
            .where((job) => _isSimilarJob(current, job))
            .take(8)
            .toList(growable: false);
        if (jobs.isNotEmpty) {
          list.assignAll(jobs);
        }
      }
    } catch (_) {}
    await getSimilar(model.value.meslek);
  }

  bool _isSimilarJob(JobModel current, JobModel other) {
    if (other.docID.isEmpty || other.docID == current.docID || other.ended) {
      return false;
    }

    final currentMeslek = normalizeSearchText(current.meslek);
    final otherMeslek = normalizeSearchText(other.meslek);
    if (currentMeslek.isNotEmpty && currentMeslek == otherMeslek) {
      return true;
    }

    final currentBrand = normalizeSearchText(current.brand);
    final otherBrand = normalizeSearchText(other.brand);
    if (currentBrand.isNotEmpty && currentBrand == otherBrand) {
      return true;
    }

    final currentTypes = current.calismaTuru.map(normalizeSearchText).toSet();
    final otherTypes = other.calismaTuru.map(normalizeSearchText).toSet();
    return currentTypes.intersection(otherTypes).isNotEmpty;
  }

  Future<void> fetchReviews(String docID) async {
    try {
      final items = await _jobRepository.fetchReviews(
        docID,
        preferCache: true,
      );
      reviews.assignAll(items);
      await _fetchReviewUsers(reviews.map((e) => e.userID));
    } catch (_) {
      reviews.clear();
    }
  }

  Future<void> _bootstrapReviews() async {
    final docId = model.value.docID;
    final cached = await _jobRepository.fetchReviews(
      docId,
      preferCache: true,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      reviews.assignAll(cached);
      unawaited(_fetchReviewUsers(reviews.map((e) => e.userID)));
    }
    await fetchReviews(docId);
  }

  Future<void> _fetchReviewUsers(Iterable<String> userIDs) async {
    final uniqueIds = userIDs.where((e) => e.trim().isNotEmpty).toSet();
    final toFetch =
        uniqueIds.where((userID) => !reviewUsers.containsKey(userID));
    if (toFetch.isEmpty) return;
    final summaries = await _userRepository.getUsers(toFetch.toList());
    for (final entry in summaries.entries) {
      reviewUsers[entry.key] = entry.value.toMap();
    }
  }

  Future<bool> submitReview({
    required int rating,
    required String comment,
  }) async {
    if (!UserModerationGuard.ensureAllowed(RestrictedAction.reviewJob)) {
      return false;
    }
    final uid = _currentUserId;
    if (uid.isEmpty) {
      AppSnackbar(
        'common.error'.tr,
        'pasaj.job_finder.review_relogin_required'.tr,
      );
      return false;
    }
    if (uid == model.value.userID) {
      AppSnackbar(
        'common.info'.tr,
        'pasaj.job_finder.review_own_forbidden'.tr,
      );
      return false;
    }

    try {
      await _jobRepository.saveReview(
        jobDocId: model.value.docID,
        userId: uid,
        rating: rating,
        comment: comment,
      );
      await _jobRepository.refreshAverageRating(model.value.docID);
      await fetchReviews(model.value.docID);
      AppSnackbar(
        'common.success'.tr,
        'pasaj.job_finder.review_saved'.tr,
      );
      return true;
    } catch (_) {
      AppSnackbar(
        'common.error'.tr,
        'pasaj.job_finder.review_save_failed'.tr,
      );
      return false;
    }
  }

  Future<void> deleteReview(String reviewID) async {
    try {
      await _jobRepository.deleteReview(
        jobDocId: model.value.docID,
        reviewId: reviewID,
      );
      await _jobRepository.refreshAverageRating(model.value.docID);
      await fetchReviews(model.value.docID);
      AppSnackbar(
        'common.info'.tr,
        'pasaj.job_finder.review_deleted'.tr,
      );
    } catch (_) {
      AppSnackbar(
        'common.error'.tr,
        'pasaj.job_finder.review_delete_failed'.tr,
      );
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
              AppSheetHeader(title: 'pasaj.job_finder.open_in_maps'.tr),
              AppSheetActionTile(
                leading: Image.asset(
                  'assets/icons/googlemaps.webp',
                  width: 30,
                  height: 30,
                ),
                title: 'pasaj.job_finder.open_google_maps'.tr,
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
                AppSheetActionTile(
                  leading: Image.asset(
                    'assets/icons/applemaps.webp',
                    width: 30,
                    height: 30,
                  ),
                  title: 'pasaj.job_finder.open_apple_maps'.tr,
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
              AppSheetActionTile(
                leading: Image.asset(
                  'assets/icons/yandexmaps.webp',
                  width: 30,
                  height: 30,
                ),
                title: 'pasaj.job_finder.open_yandex_maps'.tr,
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

  Future<void> checkBasvuru(String docID) async {
    try {
      final uid = _currentUserId;
      if (uid.isEmpty) {
        basvuruldu.value = false;
        return;
      }
      basvuruldu.value = await _jobRepository.hasApplication(docID, uid);
    } catch (_) {
      basvuruldu.value = false;
    }
  }

  /// Dual-write başvuru toggle with batch
  Future<void> toggleBasvuru(String docId) async {
    final uid = _currentUserId;
    if (uid.isEmpty) {
      AppSnackbar('common.error'.tr, 'pasaj.job_finder.relogin_required'.tr);
      return;
    }
    try {
      final wasApplied = await _jobRepository.hasApplication(docId, uid);
      final job = model.value;
      final title = job.ilanBasligi.isNotEmpty ? job.ilanBasligi : job.meslek;
      final currentUserSummary = await _userSummaryResolver.resolve(
        uid,
        preferCache: true,
      );
      final applicantName = currentUserSummary?.displayName.trim() ?? '';
      final applicantImage =
          currentUserSummary?.avatarUrl.trim() ?? kDefaultAvatarUrl;
      final applicantNickname =
          currentUserSummary?.nickname.trim().isNotEmpty == true
              ? currentUserSummary!.nickname.trim()
              : (currentUserSummary?.username.trim() ?? '');

      await _jobRepository.toggleApplication(
        jobDocId: docId,
        ownerUserId: model.value.userID,
        userId: uid,
        jobTitle: title,
        companyName: job.brand,
        companyLogo: job.logo,
        applicantName: applicantName,
        applicantNickname: applicantNickname,
        applicantPfImage: applicantImage,
      );
      basvuruldu.value = !wasApplied;
      if (!wasApplied) {
        AppSnackbar(
          'common.success'.tr,
          'pasaj.job_finder.application_sent'.tr,
        );
      }
    } catch (_) {
      AppSnackbar(
        'common.error'.tr,
        'pasaj.job_finder.application_failed'.tr,
      );
    }
  }

  Future<void> goToEdit() async {
    final result =
        await Get.to<JobModel?>(JobCreator(existingJob: model.value));
    if (result != null) {
      try {
        final refreshed = await _jobRepository.fetchById(
          model.value.docID,
          preferCache: false,
          forceRefresh: true,
        );
        if (refreshed != null) {
          model.value = refreshed;
        }
      } catch (_) {}
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
    final existing = await _jobRepository.fetchById(docId,
        preferCache: false, forceRefresh: true);

    if (existing == null) {
      throw Exception('pasaj.job_finder.listing_not_found'.tr);
    }

    await _jobRepository.unpublishJob(docId);

    final refreshed = await _jobRepository.fetchById(docId,
        preferCache: false, forceRefresh: true);
    if (refreshed != null) {
      model.value = refreshed;
    }
  }
}
