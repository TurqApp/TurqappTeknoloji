part of 'my_applications_controller.dart';

extension MyApplicationsControllerRuntimePart on MyApplicationsController {
  Future<void> _bootstrapApplicationsImpl() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      isLoading.value = false;
      return;
    }
    final cached = await _subcollectionRepository.getEntries(
      uid,
      subcollection: 'myApplications',
      orderByField: 'timeStamp',
      descending: true,
      preferCache: true,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      applications.value = cached
          .map((doc) => JobApplicationModel.fromMap(doc.data, doc.id))
          .toList(growable: false);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'jobs:my_applications:$uid',
        minInterval: MyApplicationsController._silentRefreshInterval,
      )) {
        unawaited(loadApplications(silent: true, forceRefresh: true));
      }
      return;
    }
    await loadApplications();
  }

  Future<void> loadApplications({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _loadApplicationsImpl(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  Future<void> _loadApplicationsImpl({
    required bool silent,
    required bool forceRefresh,
  }) async {
    if (!silent) {
      isLoading.value = true;
    }
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isEmpty) return;
      final items = await _subcollectionRepository.getEntries(
        uid,
        subcollection: 'myApplications',
        orderByField: 'timeStamp',
        descending: true,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );

      applications.value = items
          .map((doc) => JobApplicationModel.fromMap(doc.data, doc.id))
          .toList(growable: false);
      SilentRefreshGate.markRefreshed('jobs:my_applications:$uid');
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelApplication(String jobDocID) =>
      _cancelApplicationImpl(jobDocID);

  Future<void> _cancelApplicationImpl(String jobDocID) async {
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isEmpty) return;

      await _jobRepository.cancelApplication(
        jobDocId: jobDocID,
        userId: uid,
      );

      applications.removeWhere((a) => a.jobDocID == jobDocID);
      await _subcollectionRepository.setEntries(
        uid,
        subcollection: 'myApplications',
        items: applications
            .map(
              (e) => UserSubcollectionEntry(
                id: e.jobDocID,
                data: e.toMap(),
              ),
            )
            .toList(growable: false),
      );
    } catch (_) {}
  }
}
