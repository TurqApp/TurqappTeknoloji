part of 'my_tutoring_applications_controller.dart';

extension MyTutoringApplicationsControllerRuntimePart
    on MyTutoringApplicationsController {
  void _handleInit() {
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    final cached = await _subcollectionRepository.getEntries(
      uid,
      subcollection: 'myTutoringApplications',
      orderByField: 'timeStamp',
      descending: true,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      applications.value = cached
          .map((doc) => TutoringApplicationModel.fromMap(doc.data, doc.id))
          .toList();
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'tutoring:applications:$uid',
        minInterval: MyTutoringApplicationsController._silentRefreshInterval,
      )) {
        unawaited(_loadApplicationsImpl(silent: true, forceRefresh: true));
      }
      return;
    }
    await _loadApplicationsImpl();
  }

  Future<void> _loadApplicationsImpl({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent || applications.isEmpty) {
      isLoading.value = true;
    }
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isEmpty) return;
      final items = await _subcollectionRepository.getEntries(
        uid,
        subcollection: 'myTutoringApplications',
        orderByField: 'timeStamp',
        descending: true,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );

      applications.value = items
          .map((doc) => TutoringApplicationModel.fromMap(doc.data, doc.id))
          .toList();
      SilentRefreshGate.markRefreshed('tutoring:applications:$uid');
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _cancelApplicationImpl(String tutoringDocID) async {
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isEmpty) return;

      await _tutoringRepository.cancelApplication(
        tutoringId: tutoringDocID,
        userId: uid,
      );

      applications.removeWhere((a) => a.tutoringDocID == tutoringDocID);
      await _subcollectionRepository.setEntries(
        uid,
        subcollection: 'myTutoringApplications',
        items: applications
            .map(
              (e) => UserSubcollectionEntry(
                id: e.tutoringDocID,
                data: e.toMap(),
              ),
            )
            .toList(growable: false),
      );
    } catch (_) {}
  }
}
