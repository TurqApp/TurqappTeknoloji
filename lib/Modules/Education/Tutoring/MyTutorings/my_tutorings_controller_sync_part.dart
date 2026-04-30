part of 'my_tutorings_controller_library.dart';

extension MyTutoringsControllerSyncPart on MyTutoringsController {
  Future<void> _bootstrapData(String currentUserId) async {
    final cached = (await _tutoringSnapshotRepository.loadCachedOwner(
          userId: currentUserId,
        ))
            .data ??
        const <TutoringModel>[];
    if (cached.isNotEmpty) {
      if (!_sameTutoringEntries(myTutorings, cached)) {
        myTutorings.assignAll(cached);
      }
      updateTutoringsStatus();
      final userIds = cached.map((t) => t.userID).toSet();
      if (userIds.isNotEmpty) {
        await fetchUsers(userIds, cacheOnly: true);
      }
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'tutoring:owner:$currentUserId',
        minInterval: MyTutoringsController._silentRefreshInterval,
      )) {
        unawaited(fetchMyTutorings(
          currentUserId,
          silent: true,
          forceRefresh: true,
        ));
      }
      return;
    }
    await fetchMyTutorings(currentUserId);
  }

  Future<void> fetchMyTutorings(
    String currentUserId, {
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent || myTutorings.isEmpty) {
      isLoading.value = true;
    }
    try {
      final tutorings = (await _tutoringSnapshotRepository.loadOwner(
            userId: currentUserId,
            forceSync: forceRefresh,
          ))
              .data ??
          const <TutoringModel>[];
      await _archiveExpiredTutorings(tutorings);
      final refreshed = (await _tutoringSnapshotRepository.loadOwner(
            userId: currentUserId,
            forceSync: true,
          ))
              .data ??
          const <TutoringModel>[];
      if (!_sameTutoringEntries(myTutorings, refreshed)) {
        myTutorings.assignAll(refreshed);
      }

      updateTutoringsStatus();

      final userIds = refreshed.map((t) => t.userID).toSet();
      if (userIds.isNotEmpty) {
        await fetchUsers(userIds);
      }
      SilentRefreshGate.markRefreshed('tutoring:owner:$currentUserId');
    } catch (e) {
      errorMessage.value = 'tutoring.load_failed'.trParams({
        'error': e.toString(),
      });
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _archiveExpiredTutorings(List<TutoringModel> tutorings) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000);
    await _tutoringRepository.markExpiredTutorings(
      tutorings,
      now: now,
      staleBefore: thirtyDaysAgo,
    );
  }

  Future<void> reactivateEndedTutoring(TutoringModel tutoring) async {
    final uid = getCurrentUserId();
    if (uid == null || tutoring.userID != uid || tutoring.ended != true) return;

    await _tutoringRepository.reactivateTutoring(tutoring.docID);

    await fetchMyTutorings(uid);
    AppSnackbar(
      'tutoring.reactivated_title'.tr,
      'tutoring.reactivated_body'.tr,
    );
  }
}
