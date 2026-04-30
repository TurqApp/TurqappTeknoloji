part of 'explore_controller.dart';

extension ExploreControllerRecentSearchPart on ExploreController {
  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  Future<void> _applyUserCacheQuota() async {
    try {
      final quotaGb = normalizeStorageBudgetPlanGb(
        await _localPreferences.getInt('offline_cache_quota_gb') ?? 3,
      );
      await StorageBudgetManager.maybeFind()?.applyPlanGb(quotaGb);
      await SegmentCacheManager.maybeFind()?.setUserLimitGB(quotaGb);
    } catch (_) {}
  }

  void _bindRecentSearchUsers() {
    _currentUserWorker?.dispose();
    _recentSearchReloadKey = _buildRecentSearchReloadKey(
      CurrentUserService.instance.currentUser,
    );
    _currentUserWorker = ever(
      CurrentUserService.instance.currentUserRx,
      (currentUser) {
        final nextKey = _buildRecentSearchReloadKey(currentUser);
        if (nextKey == _recentSearchReloadKey) {
          return;
        }
        _recentSearchReloadKey = nextKey;
        unawaited(_reloadRecentSearchUsers());
      },
    );
    unawaited(_reloadRecentSearchUsers());
  }

  String _buildRecentSearchReloadKey(dynamic currentUser) {
    final userID = (currentUser?.userID ?? _currentUid).toString();
    if (userID.isEmpty) {
      return '';
    }

    final lastSearches = currentUser?.lastSearchList;
    if (lastSearches is! List) {
      return userID;
    }

    return '$userID::${lastSearches.map((e) => e.toString()).join('|')}';
  }

  Future<void> _reloadRecentSearchUsers() async {
    final currentUserID = _currentUid;
    if (currentUserID.isEmpty) {
      recentSearchUsers.clear();
      await _saveRecentSearchUsersCache();
      return;
    }

    final ids = await _fetchRecentSearchIds(currentUserID);
    if (ids.isEmpty) {
      recentSearchUsers.clear();
      await _saveRecentSearchUsersCache();
      return;
    }

    final orderedIds = <String>[];
    final seen = <String>{};
    for (final id in ids) {
      final normalized = id.trim();
      if (normalized.isEmpty) continue;
      if (!seen.add(normalized)) continue;
      orderedIds.add(normalized);
    }
    if (orderedIds.isEmpty) {
      recentSearchUsers.clear();
      await _saveRecentSearchUsersCache();
      return;
    }

    final sorted = <OgrenciModel>[];
    final profileMap = await _userCache.getProfiles(
      orderedIds,
      preferCache: true,
      cacheOnly: !ContentPolicy.isConnected,
    );
    for (final id in orderedIds) {
      final data = profileMap[id];
      if (data == null) continue;
      final nickname = (data['nickname'] ?? '').toString();
      if (nickname.isEmpty) continue;
      sorted.add(
        OgrenciModel(
          userID: id,
          firstName: (data['firstName'] ?? '').toString(),
          lastName: (data['lastName'] ?? '').toString(),
          avatarUrl: (data['avatarUrl'] ?? '').toString(),
          nickname: nickname,
        ),
      );
    }
    final filtered = await _filterPendingOrDeletedUsers(sorted);
    recentSearchUsers.value = filtered;
    await _saveRecentSearchUsersCache();
  }

  Future<List<String>> _fetchRecentSearchIds(String currentUserID) async {
    try {
      final entries = await _subcollectionRepository.getEntries(
        currentUserID,
        subcollection: 'lastSearches',
        preferCache: true,
        forceRefresh: false,
      );
      final docs = entries.toList()
        ..sort((a, b) {
          final aData = a.data;
          final bData = b.data;
          final aTs = (aData['updatedDate'] is num)
              ? (aData['updatedDate'] as num).toInt()
              : ((aData['timeStamp'] is num)
                  ? (aData['timeStamp'] as num).toInt()
                  : 0);
          final bTs = (bData['updatedDate'] is num)
              ? (bData['updatedDate'] as num).toInt()
              : ((bData['timeStamp'] is num)
                  ? (bData['timeStamp'] as num).toInt()
                  : 0);
          return bTs.compareTo(aTs);
        });
      return docs
          .take(_recentSearchUsersLimit)
          .map((d) => d.id.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return CurrentUserService.instance.currentUser?.lastSearchList ??
          const <String>[];
    }
  }

  String? _recentSearchUsersCacheKey() {
    final uid = _currentUid;
    if (uid.isEmpty) return null;
    return '$_recentSearchUsersCachePrefix$uid';
  }

  Future<void> _loadRecentSearchUsersCache() async {
    try {
      final key = _recentSearchUsersCacheKey();
      if (key == null) return;
      final raw = await _localPreferences.getString(key);
      if (raw == null || raw.trim().isEmpty) return;
      final parsed = jsonDecode(raw);
      if (parsed is! List) {
        await _localPreferences.remove(key);
        return;
      }

      final restored = <OgrenciModel>[];
      for (final item in parsed) {
        if (item is! Map) continue;
        final map = item.map((k, v) => MapEntry(k.toString(), v));
        final userID = (map['userID'] ?? '').toString().trim();
        final nickname = (map['nickname'] ?? '').toString().trim();
        if (userID.isEmpty || nickname.isEmpty) continue;
        restored.add(
          OgrenciModel(
            userID: userID,
            firstName: (map['firstName'] ?? '').toString(),
            lastName: (map['lastName'] ?? '').toString(),
            avatarUrl: (map['avatarUrl'] ?? '').toString(),
            nickname: nickname,
          ),
        );
      }
      if (restored.isNotEmpty) {
        recentSearchUsers.value = restored;
      } else if (parsed.isNotEmpty) {
        await _localPreferences.remove(key);
      }
    } catch (_) {
      try {
        final key = _recentSearchUsersCacheKey();
        if (key == null) return;
        await _localPreferences.remove(key);
      } catch (_) {}
    }
  }

  Future<void> _saveRecentSearchUsersCache() async {
    try {
      final key = _recentSearchUsersCacheKey();
      if (key == null) return;
      final payload = recentSearchUsers
          .take(_recentSearchUsersLimit)
          .map(
            (u) => <String, dynamic>{
              'userID': u.userID,
              'nickname': u.nickname,
              'firstName': u.firstName,
              'lastName': u.lastName,
              'avatarUrl': u.avatarUrl,
            },
          )
          .toList(growable: false);
      await _localPreferences.setString(key, jsonEncode(payload));
    } catch (_) {}
  }

  Future<void> saveRecentSearch(String targetUid) async {
    final currentUserID = _currentUid;
    final cleanTarget = targetUid.trim();
    if (currentUserID.isEmpty ||
        cleanTarget.isEmpty ||
        cleanTarget == currentUserID) {
      return;
    }
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _subcollectionRepository.upsertEntry(
        currentUserID,
        subcollection: 'lastSearches',
        docId: cleanTarget,
        data: {
          "userID": cleanTarget,
          "updatedDate": now,
          "timeStamp": now,
        },
      );
      final existing = await _subcollectionRepository.getEntries(
        currentUserID,
        subcollection: 'lastSearches',
        preferCache: true,
      );
      final next = <UserSubcollectionEntry>[
        UserSubcollectionEntry(
          id: cleanTarget,
          data: {
            'userID': cleanTarget,
            'updatedDate': now,
            'timeStamp': now,
          },
        ),
        ...existing.where((e) => e.id != cleanTarget),
      ];
      await _subcollectionRepository.setEntries(
        currentUserID,
        subcollection: 'lastSearches',
        items: next.take(200).toList(growable: false),
      );
      await CurrentUserService.instance.addRecentSearchLocal(cleanTarget);
    } catch (_) {
    } finally {
      await _reloadRecentSearchUsers();
    }
  }

  Future<void> removeRecentSearch(String targetUid) async {
    final currentUserID = _currentUid;
    final cleanTarget = targetUid.trim();
    if (currentUserID.isEmpty || cleanTarget.isEmpty) {
      return;
    }

    final before = List<OgrenciModel>.from(recentSearchUsers);
    recentSearchUsers.removeWhere((e) => e.userID == cleanTarget);
    recentSearchUsers.refresh();
    await _saveRecentSearchUsersCache();

    try {
      await _subcollectionRepository.deleteEntry(
        currentUserID,
        subcollection: 'lastSearches',
        docId: cleanTarget,
      );
      final existing = await _subcollectionRepository.getEntries(
        currentUserID,
        subcollection: 'lastSearches',
        preferCache: true,
      );
      await _subcollectionRepository.setEntries(
        currentUserID,
        subcollection: 'lastSearches',
        items:
            existing.where((e) => e.id != cleanTarget).toList(growable: false),
      );
      await CurrentUserService.instance.removeRecentSearchLocal(cleanTarget);
    } catch (_) {
      recentSearchUsers.value = before;
      await _saveRecentSearchUsersCache();
    } finally {
      await _reloadRecentSearchUsers();
    }
  }

  Future<void> refreshRecentSearchUsers() async {
    await _reloadRecentSearchUsers();
  }
}
