part of 'blocked_users_controller.dart';

extension BlockedUsersControllerDataPart on BlockedUsersController {
  Future<void> _bootstrapBlockedUsers() async {
    final hasLocal = await _hydrateBlockedUsersFromCache();
    if (hasLocal) {
      isLoading.value = false;
      final uid = _currentUid;
      if (uid.isNotEmpty &&
          SilentRefreshGate.shouldRefresh(
            'blocked_users:$uid',
            minInterval: BlockedUsersController._silentRefreshInterval,
          )) {
        unawaited(fetchBlockedUserIDsAndDetails(
          silent: true,
          forceRefresh: true,
        ));
      }
      return;
    }
    await fetchBlockedUserIDsAndDetails();
  }

  Future<bool> _hydrateBlockedUsersFromCache() async {
    final uid = _currentUid;
    final entries = await _subcollectionRepository.getEntries(
      uid,
      subcollection: 'blockedUsers',
      preferCache: true,
      cacheOnly: true,
    );
    if (entries.isNotEmpty) {
      blockedUsers.value = entries.map((d) => d.id).toList();
      await fetchBlockedUserDetails(cacheOnly: true);
      return blockedUserDetails.isNotEmpty;
    }

    final data = await _userRepository.getUserRaw(uid, cacheOnly: true);
    if (data != null && data.containsKey("blockedUsers")) {
      blockedUsers.value = List<String>.from(data["blockedUsers"] ?? const []);
      await fetchBlockedUserDetails(cacheOnly: true);
      return blockedUsers.isNotEmpty;
    }
    return false;
  }

  Future<void> fetchBlockedUserIDsAndDetails({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent) {
      isLoading.value = true;
    }
    try {
      final uid = _currentUid;
      final entries = await _subcollectionRepository.getEntries(
        uid,
        subcollection: 'blockedUsers',
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      if (entries.isNotEmpty) {
        blockedUsers.value = entries.map((d) => d.id).toList();
        await fetchBlockedUserDetails(
          cacheOnly: false,
          preferCache: !forceRefresh,
        );
        SilentRefreshGate.markRefreshed('blocked_users:$uid');
        return;
      }

      final data = await _userRepository.getUserRaw(
        uid,
        preferCache: !forceRefresh,
        forceServer: forceRefresh,
      );
      if (data != null && data.containsKey("blockedUsers")) {
        blockedUsers.value =
            List<String>.from(data["blockedUsers"] ?? const <String>[]);
        await fetchBlockedUserDetails(
          cacheOnly: false,
          preferCache: !forceRefresh,
        );
        SilentRefreshGate.markRefreshed('blocked_users:$uid');
        return;
      }
      blockedUsers.clear();
      blockedUserDetails.clear();
      SilentRefreshGate.markRefreshed('blocked_users:$uid');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchBlockedUserDetails({
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    if (blockedUsers.isEmpty) {
      blockedUserDetails.clear();
      return;
    }

    final profiles = await _userSummaryResolver.resolveMany(
      blockedUsers.toList(),
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    final nextDetails = <OgrenciModel>[];
    for (final userID in blockedUsers) {
      final data = profiles[userID];
      if (data != null) {
        nextDetails.add(
          OgrenciModel(
            userID: userID,
            firstName: data.displayName,
            lastName: '',
            avatarUrl: data.avatarUrl,
            nickname: data.preferredName,
          ),
        );
      }
    }
    blockedUserDetails.assignAll(nextDetails);
  }
}
