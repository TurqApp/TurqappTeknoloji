part of 'my_tutorings_controller.dart';

extension MyTutoringsControllerSyncPart on MyTutoringsController {
  Future<void> _bootstrapData(String currentUserId) async {
    final cached = await _tutoringRepository.fetchByOwner(
      currentUserId,
      cacheOnly: true,
    );
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
      final tutorings = await _tutoringRepository.fetchByOwner(
        currentUserId,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      await _archiveExpiredTutorings(tutorings);
      final refreshed = await _tutoringRepository.fetchByOwner(
        currentUserId,
        preferCache: false,
        forceRefresh: true,
      );
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
    final batch = FirebaseFirestore.instance.batch();
    var changed = false;

    for (final tutoring in tutorings) {
      if (tutoring.ended == true) continue;
      if (tutoring.timeStamp < thirtyDaysAgo) {
        batch.update(
          FirebaseFirestore.instance
              .collection('educators')
              .doc(tutoring.docID),
          {'ended': true, 'endedAt': now},
        );
        changed = true;
      }
    }

    if (changed) {
      await batch.commit();
    }
  }

  Future<void> reactivateEndedTutoring(TutoringModel tutoring) async {
    final uid = getCurrentUserId();
    if (uid == null || tutoring.userID != uid || tutoring.ended != true) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    await FirebaseFirestore.instance
        .collection('educators')
        .doc(tutoring.docID)
        .update({
      'ended': false,
      'endedAt': 0,
      'timeStamp': now,
    });

    await fetchMyTutorings(uid);
    AppSnackbar(
      'tutoring.reactivated_title'.tr,
      'tutoring.reactivated_body'.tr,
    );
  }
}
