part of 'user_summary_resolver.dart';

extension UserSummaryResolverDataPart on UserSummaryResolver {
  Future<Map<String, UserSummary>> resolveMany(
    List<String> uids, {
    bool preferCache = true,
    bool cacheOnly = false,
    bool preferTypesenseCardsForMisses = false,
  }) {
    return _resolveManyInternal(
      uids,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
      preferTypesenseCardsForMisses: preferTypesenseCardsForMisses,
    );
  }

  Future<Map<String, UserSummary>> _resolveManyInternal(
    List<String> uids, {
    required bool preferCache,
    required bool cacheOnly,
    required bool preferTypesenseCardsForMisses,
  }) async {
    final local = await _users.getUsers(
      uids,
      preferCache: preferCache,
      cacheOnly: preferTypesenseCardsForMisses ? true : cacheOnly,
    );
    final missing = uids
        .map((uid) => uid.trim())
        .where((uid) => uid.isNotEmpty && !local.containsKey(uid))
        .toSet()
        .toList(growable: false);
    if (missing.isEmpty) return local;
    if (cacheOnly) return local;

    final cards = await _typesenseCards.getUserCardsByIds(
      missing,
      preferCache: preferCache,
      cacheOnly: false,
    );
    for (final entry in cards.entries) {
      final uid = entry.key.trim();
      final card = entry.value;
      if (uid.isEmpty || card.isEmpty) continue;
      await _users.putUserRaw(uid, card);
      local[uid] = UserSummary.fromMap(uid, card);
    }
    if (!preferTypesenseCardsForMisses) {
      return local;
    }
    final unresolved =
        missing.where((uid) => !local.containsKey(uid)).toList(growable: false);
    if (unresolved.isEmpty) {
      return local;
    }
    final server = await _users.getUsers(
      unresolved,
      preferCache: false,
      cacheOnly: false,
    );
    local.addAll(server);
    return local;
  }

  UserSummary resolveFromMaps(
    String uid, {
    Map<String, dynamic> embedded = const <String, dynamic>{},
    Map<String, dynamic> profile = const <String, dynamic>{},
  }) {
    final normalizedUid = uid.trim().isNotEmpty
        ? uid.trim()
        : (embedded['userID'] ??
                embedded['uid'] ??
                profile['userID'] ??
                profile['uid'] ??
                '')
            .toString()
            .trim();
    final merged = <String, dynamic>{}
      ..addAll(profile)
      ..addAll(embedded);
    final nickname = _pickFirstSummaryText(<Object?>[
      merged['nickname'],
      merged['username'],
      merged['handle'],
      merged['displayName'],
      merged['authorNickname'],
      merged['authorDisplayName'],
    ]);
    final displayName = _pickFirstSummaryText(<Object?>[
      merged['displayName'],
      merged['fullName'],
      merged['authorDisplayName'],
      nickname,
    ]);
    final avatarUrl = resolveAvatarUrl(embedded, profile: profile);
    final rozet = _pickFirstSummaryText(<Object?>[
      merged['rozet'],
      merged['badge'],
    ]);
    final token = _pickFirstSummaryText(<Object?>[
      merged['token'],
      merged['pushToken'],
    ]);
    return UserSummary(
      userID: normalizedUid,
      displayName: displayName,
      nickname: nickname,
      username: _pickFirstSummaryText(<Object?>[
        merged['username'],
        nickname,
      ]),
      avatarUrl: avatarUrl,
      bio: _pickFirstSummaryText(<Object?>[
        merged['bio'],
      ]),
      rozet: rozet,
      token: token,
      followerCount: _summaryInt(
        merged['followerCount'] ?? merged['followersCount'],
      ),
      followingCount: _summaryInt(merged['followingCount']),
      postCount: _summaryInt(merged['postCount']),
      isPrivate: _summaryBool(merged['isPrivate']),
      isDeleted: _summaryBool(merged['isDeleted']),
      isApproved: _summaryBool(merged['isApproved']),
    );
  }
}

String _pickFirstSummaryText(List<Object?> candidates) {
  for (final candidate in candidates) {
    final value = candidate?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}

int _summaryInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  final value = raw?.toString().trim() ?? '';
  if (value.isEmpty) return 0;
  return int.tryParse(value) ?? num.tryParse(value)?.toInt() ?? 0;
}

bool _summaryBool(Object? raw) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  final value = raw?.toString().trim().toLowerCase() ?? '';
  return value == 'true' || value == '1' || value == 'yes';
}
