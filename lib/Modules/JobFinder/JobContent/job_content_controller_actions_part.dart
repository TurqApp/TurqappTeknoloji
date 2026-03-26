part of 'job_content_controller.dart';

extension JobContentControllerActionsPart on JobContentController {
  Future<void> _reactivateEndedJobImpl(JobModel model) async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    if (model.userID != uid || !model.ended) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await _jobRepository.fetchById(
      model.docID,
      preferCache: false,
      forceRefresh: true,
    );
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

    final myJobAdsController = maybeFindMyJobAdsController();
    if (myJobAdsController != null) {
      await myJobAdsController.getActive();
    }
    final finder = maybeFindJobFinderController();
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

  Future<void> _shareJobImpl(JobModel model) async {
    final uid = CurrentUserService.instance.effectiveUserId;
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
