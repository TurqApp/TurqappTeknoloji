part of 'job_details_controller.dart';

extension JobDetailsControllerActionsPart on JobDetailsController {
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
                    'https://www.google.com/maps/search/?api=1&query=$lat,$long',
                  );
                  if (await canLaunchUrl(url)) {
                    await confirmAndLaunchExternalUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
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
                      await confirmAndLaunchExternalUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
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
                    'yandexmaps://maps.yandex.ru/?ll=$long,$lat&z=10',
                  );
                  if (await canLaunchUrl(appUrl)) {
                    await launchUrl(
                      appUrl,
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    final webUrl = Uri.parse(
                      'https://yandex.com/maps/?ll=$long,$lat&z=10',
                    );
                    if (await canLaunchUrl(webUrl)) {
                      await confirmAndLaunchExternalUrl(
                        webUrl,
                        mode: LaunchMode.externalApplication,
                      );
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
    Get.to(
      () => ApplicationReview(
        jobDocID: job.docID,
        jobTitle: job.ilanBasligi.isNotEmpty ? job.ilanBasligi : job.meslek,
      ),
    );
  }

  Future<void> unpublishAd() async {
    final docId = model.value.docID;
    final existing = await _jobRepository.fetchById(
      docId,
      preferCache: false,
      forceRefresh: true,
    );

    if (existing == null) {
      throw Exception('pasaj.job_finder.listing_not_found'.tr);
    }

    await _jobRepository.unpublishJob(docId);

    final refreshed = await _jobRepository.fetchById(
      docId,
      preferCache: false,
      forceRefresh: true,
    );
    if (refreshed != null) {
      model.value = refreshed;
    }
  }
}
