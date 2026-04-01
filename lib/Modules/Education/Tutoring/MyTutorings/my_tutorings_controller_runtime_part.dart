part of 'my_tutorings_controller_library.dart';

extension MyTutoringsControllerRuntimePart on MyTutoringsController {
  bool _sameTutoringEntries(
    List<TutoringModel> current,
    List<TutoringModel> next,
  ) {
    final currentKeys = current
        .map(
          (item) => [
            item.docID,
            item.baslik,
            item.brans,
            item.sehir,
            item.ilce,
            item.fiyat,
            item.timeStamp,
            item.viewCount ?? 0,
            item.applicationCount ?? 0,
            item.ended,
            item.endedAt,
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (item) => [
            item.docID,
            item.baslik,
            item.brans,
            item.sehir,
            item.ilce,
            item.fiyat,
            item.timeStamp,
            item.viewCount ?? 0,
            item.applicationCount ?? 0,
            item.ended,
            item.endedAt,
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

  void _handleMyTutoringsInit() {
    final uid = getCurrentUserId();
    if (uid != null) {
      unawaited(_bootstrapData(uid));
    } else {
      errorMessage.value = 'tutoring.user_id_missing'.tr;
      isLoading.value = false;
    }
  }

  void _handleMyTutoringsClose() {
    pageController.dispose();
  }

  void updateTutoringsStatus() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final thirtyDaysInMillis = 30 * 24 * 60 * 60 * 1000;
    activeTutorings.clear();
    expiredTutorings.clear();

    for (var tutoring in myTutorings) {
      if (tutoring.ended == true ||
          now - tutoring.timeStamp > thirtyDaysInMillis) {
        expiredTutorings.add(tutoring);
      } else {
        activeTutorings.add(tutoring);
      }
    }
  }

  Future<void> fetchUsers(
    Set<String> userIds, {
    bool cacheOnly = false,
  }) async {
    final toFetch = userIds.where((id) => !users.containsKey(id)).toList();
    if (toFetch.isEmpty) return;

    try {
      final rawUsers = await _userSummaryResolver.resolveMany(
        toFetch,
        preferCache: true,
        cacheOnly: cacheOnly,
      );
      for (final entry in rawUsers.entries) {
        users[entry.key] = entry.value.toMap();
      }
    } catch (e) {
      errorMessage.value = 'tutoring.user_load_failed'.trParams({
        'error': e.toString(),
      });
    }
  }

  String? getCurrentUserId() {
    final uid = CurrentUserService.instance.effectiveUserId;
    return uid.isNotEmpty ? uid : null;
  }

  void goToPage(int index) {
    selection.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
