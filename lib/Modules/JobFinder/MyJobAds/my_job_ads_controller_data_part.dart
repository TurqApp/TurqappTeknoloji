part of 'my_job_ads_controller_library.dart';

extension MyJobAdsControllerDataPart on MyJobAdsController {
  Future<void> _bootstrapImpl() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      isLoadingActive.value = false;
      isLoadingDeactive.value = false;
      return;
    }

    final cached = (await _jobHomeSnapshotRepository.loadCachedOwner(
          userId: uid,
        ))
            .data ??
        const <JobModel>[];
    if (cached.isNotEmpty) {
      _applyOwnerJobs(cached);
      isLoadingActive.value = false;
      isLoadingDeactive.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'jobs:my_ads:owner:$uid',
        minInterval: _myJobAdsSilentRefreshInterval,
      )) {
        unawaited(
          _refreshOwnerJobsImpl(
            silent: true,
            forceRefresh: true,
            updateActiveLoading: false,
            updateDeactiveLoading: false,
          ),
        );
      }
      return;
    }

    await _refreshOwnerJobsImpl(
      silent: false,
      forceRefresh: false,
      updateActiveLoading: true,
      updateDeactiveLoading: true,
    );
  }

  Future<void> _getActiveImpl({
    required bool silent,
    required bool forceRefresh,
  }) =>
      _refreshOwnerJobsImpl(
        silent: silent,
        forceRefresh: forceRefresh,
        updateActiveLoading: true,
        updateDeactiveLoading: false,
      );

  Future<void> _getDeactiveImpl({
    required bool silent,
    required bool forceRefresh,
  }) =>
      _refreshOwnerJobsImpl(
        silent: silent,
        forceRefresh: forceRefresh,
        updateActiveLoading: false,
        updateDeactiveLoading: true,
      );

  Future<void> _refreshOwnerJobsImpl({
    required bool silent,
    required bool forceRefresh,
    required bool updateActiveLoading,
    required bool updateDeactiveLoading,
  }) async {
    if (!silent) {
      if (updateActiveLoading) {
        isLoadingActive.value = true;
      }
      if (updateDeactiveLoading) {
        isLoadingDeactive.value = true;
      }
    }
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isEmpty) return;
      final items = forceRefresh
          ? ((await _jobHomeSnapshotRepository.loadOwner(
                userId: uid,
                forceSync: true,
              ))
                  .data ??
              const <JobModel>[])
          : ((await _jobHomeSnapshotRepository.loadCachedOwner(
                userId: uid,
              ))
                  .data ??
              (await _jobHomeSnapshotRepository.loadOwner(
                userId: uid,
                forceSync: true,
              ))
                  .data ??
              const <JobModel>[]);
      _applyOwnerJobs(items);
      SilentRefreshGate.markRefreshed('jobs:my_ads:owner:$uid');
    } catch (_) {
    } finally {
      if (updateActiveLoading) {
        isLoadingActive.value = false;
      }
      if (updateDeactiveLoading) {
        isLoadingDeactive.value = false;
      }
    }
  }

  void _applyOwnerJobs(List<JobModel> jobs) {
    final activeJobs = jobs.where((job) => !job.ended).toList(growable: false);
    final endedJobs = jobs.where((job) => job.ended).toList(growable: false);
    final nextActive = _filterAndNormalizeExpiredImpl(activeJobs);
    if (!_sameJobEntries(active, nextActive)) {
      active.assignAll(nextActive);
    }
    if (!_sameJobEntries(deactive, endedJobs)) {
      deactive.assignAll(endedJobs);
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
