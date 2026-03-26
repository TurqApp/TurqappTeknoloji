part of 'my_job_ads_controller.dart';

extension MyJobAdsControllerDataPart on MyJobAdsController {
  Future<void> _bootstrapImpl() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      isLoadingActive.value = false;
      isLoadingDeactive.value = false;
      return;
    }

    final cachedActive = await _jobRepository.fetchByOwnerAndEnded(
      uid,
      ended: false,
      cacheOnly: true,
    );
    if (cachedActive.isNotEmpty) {
      final nextActive = _filterAndNormalizeExpiredImpl(cachedActive);
      if (!_sameJobEntries(active, nextActive)) {
        active.assignAll(nextActive);
      }
      isLoadingActive.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'jobs:my_ads:active:$uid',
        minInterval: _myJobAdsSilentRefreshInterval,
      )) {
        unawaited(getActive(silent: true, forceRefresh: true));
      }
    } else {
      await getActive();
    }

    final cachedEnded = await _jobRepository.fetchByOwnerAndEnded(
      uid,
      ended: true,
      cacheOnly: true,
    );
    if (cachedEnded.isNotEmpty) {
      if (!_sameJobEntries(deactive, cachedEnded)) {
        deactive.assignAll(cachedEnded);
      }
      isLoadingDeactive.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'jobs:my_ads:ended:$uid',
        minInterval: _myJobAdsSilentRefreshInterval,
      )) {
        unawaited(getDeactive(silent: true, forceRefresh: true));
      }
      return;
    }

    if (deactive.isEmpty) {
      await getDeactive();
    }
  }

  Future<void> _getActiveImpl({
    required bool silent,
    required bool forceRefresh,
  }) async {
    if (!silent) {
      isLoadingActive.value = true;
    }
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isEmpty) return;
      final jobs = await _jobRepository.fetchByOwnerAndEnded(
        uid,
        ended: false,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      final nextActive = _filterAndNormalizeExpiredImpl(jobs);
      if (!_sameJobEntries(active, nextActive)) {
        active.assignAll(nextActive);
      }
      SilentRefreshGate.markRefreshed('jobs:my_ads:active:$uid');
    } catch (_) {
    } finally {
      isLoadingActive.value = false;
    }
  }

  Future<void> _getDeactiveImpl({
    required bool silent,
    required bool forceRefresh,
  }) async {
    if (!silent) {
      isLoadingDeactive.value = true;
    }
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isEmpty) return;
      final nextDeactive = await _jobRepository.fetchByOwnerAndEnded(
        uid,
        ended: true,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      if (!_sameJobEntries(deactive, nextDeactive)) {
        deactive.value = nextDeactive;
      }
      SilentRefreshGate.markRefreshed('jobs:my_ads:ended:$uid');
    } catch (_) {
    } finally {
      isLoadingDeactive.value = false;
    }
  }

  List<JobModel> _filterAndNormalizeExpiredImpl(List<JobModel> jobs) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000);
    final validJobs = <JobModel>[];

    for (final job in jobs) {
      if (job.timeStamp < thirtyDaysAgo) {
        unawaited(FirebaseFirestore.instance
            .collection(JobCollection.name)
            .doc(job.docID)
            .update({"ended": true}));
      } else {
        validJobs.add(job);
      }
    }

    return validJobs;
  }
}
