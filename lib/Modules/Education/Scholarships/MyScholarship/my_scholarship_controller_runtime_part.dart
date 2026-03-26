part of 'my_scholarship_controller_library.dart';

class MyScholarshipControllerRuntimePart {
  const MyScholarshipControllerRuntimePart(this.controller);

  final MyScholarshipController controller;

  Future<void> bootstrapMyScholarships() async {
    final userId = CurrentUserService.instance.effectiveUserId;
    if (userId.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.login_required'.tr);
      controller.isLoading.value = false;
      return;
    }

    try {
      final cachedRaw =
          await controller._scholarshipRepository.fetchMyScholarshipsRaw(
        userId,
        limit: 50,
        cacheOnly: true,
      );
      if (cachedRaw.isNotEmpty) {
        controller.myScholarships.assignAll(
          await controller.buildScholarshipCards(
            cachedRaw,
            userCacheOnly: true,
          ),
        );
        controller.isLoading.value = false;
        if (SilentRefreshGate.shouldRefresh(
          'scholarships:mine:$userId',
          minInterval: MyScholarshipController._silentRefreshInterval,
        )) {
          unawaited(
            controller.fetchMyScholarships(
              silent: true,
              forceRefresh: true,
            ),
          );
        }
        return;
      }
    } catch (_) {}

    await controller.fetchMyScholarships();
  }

  Future<void> fetchMyScholarships({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final userId = CurrentUserService.instance.effectiveUserId;
    if (userId.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.login_required'.tr);
      controller.isLoading.value = false;
      return;
    }

    final shouldShowLoader = !silent && controller.myScholarships.isEmpty;
    if (shouldShowLoader) {
      controller.isLoading.value = true;
    }
    try {
      final rawScholarships =
          await controller._scholarshipRepository.fetchMyScholarshipsRaw(
        userId,
        limit: 50,
        forceRefresh: forceRefresh,
      );
      controller.myScholarships.value =
          await controller.buildScholarshipCards(rawScholarships);
      SilentRefreshGate.markRefreshed('scholarships:mine:$userId');
    } catch (_) {
      AppSnackbar('common.error'.tr, 'common.data_load_failed'.tr);
    } finally {
      if (shouldShowLoader || controller.myScholarships.isEmpty) {
        controller.isLoading.value = false;
      }
    }
  }

  Future<List<Map<String, dynamic>>> buildScholarshipCards(
    List<Map<String, dynamic>> rawScholarships, {
    bool userCacheOnly = false,
  }) async {
    final scholarships = <Map<String, dynamic>>[];
    final userIds = <String>{};
    for (final data in rawScholarships) {
      final userID = data['userID'] as String? ?? '';
      if (userID.isNotEmpty) userIds.add(userID);
    }

    final userDataMap = <String, Map<String, dynamic>>{};
    final fetchedUsers = userIds.isEmpty
        ? <String, UserSummary>{}
        : await controller._userSummaryResolver.resolveMany(
            userIds.toList(),
            preferCache: true,
            cacheOnly: userCacheOnly,
          );
    for (final entry in fetchedUsers.entries) {
      final user = entry.value;
      userDataMap[entry.key] = {
        'avatarUrl': user.avatarUrl,
        'nickname': user.nickname,
        'displayName': user.preferredName,
        'userID': entry.key,
      };
    }

    for (final data in rawScholarships) {
      try {
        final userID = data['userID'] as String? ?? '';
        final userData = userDataMap[userID] ??
            <String, dynamic>{
              'avatarUrl': '',
              'nickname': '',
              'displayName': '',
              'userID': userID,
            };

        scholarships.add(
          <String, dynamic>{
            'model': IndividualScholarshipsModel.fromJson(data),
            'type': kIndividualScholarshipType,
            'userData': userData,
            'docId': (data['docId'] ?? '').toString(),
          },
        );
      } catch (_) {
        AppSnackbar('common.error'.tr, 'common.item_process_failed'.tr);
      }
    }
    return scholarships;
  }
}
