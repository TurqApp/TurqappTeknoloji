import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/typesense_user_card_cache_service.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';

class UserSummaryResolver extends GetxService {
  static UserSummaryResolver _ensureService() {
    if (Get.isRegistered<UserSummaryResolver>()) {
      return Get.find<UserSummaryResolver>();
    }
    return Get.put(UserSummaryResolver(), permanent: true);
  }

  static UserSummaryResolver ensure() {
    return _ensureService();
  }

  UserRepository get _users => UserRepository.ensure();
  TypesenseUserCardCacheService get _typesenseCards =>
      TypesenseUserCardCacheService.ensure();

  Future<UserSummary?> resolve(
    String uid, {
    bool preferCache = true,
    bool cacheOnly = false,
    bool forceServer = false,
  }) async {
    if (uid.trim().isEmpty) return null;
    if (!forceServer) {
      final local = await _users.getUser(
        uid,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      if (local != null) return local;
      final cards = await _typesenseCards.getUserCardsByIds(
        <String>[uid],
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      final card = cards[uid.trim()];
      if (card != null && card.isNotEmpty) {
        await _users.putUserRaw(uid.trim(), card);
        return UserSummary.fromMap(uid.trim(), card);
      }
      return null;
    }
    final raw = await _users.getUserRaw(
      uid,
      preferCache: false,
      cacheOnly: cacheOnly,
      forceServer: true,
    );
    if (raw == null || raw.isEmpty) return null;
    return UserSummary.fromMap(uid.trim(), raw);
  }

  Future<Map<String, UserSummary>> resolveMany(
    List<String> uids, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) {
    return _resolveManyInternal(
      uids,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
  }

  Future<Map<String, UserSummary>> _resolveManyInternal(
    List<String> uids, {
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final local = await _users.getUsers(
      uids,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    final missing = uids
        .map((uid) => uid.trim())
        .where((uid) => uid.isNotEmpty && !local.containsKey(uid))
        .toSet()
        .toList(growable: false);
    if (missing.isEmpty) return local;

    final cards = await _typesenseCards.getUserCardsByIds(
      missing,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    for (final entry in cards.entries) {
      final uid = entry.key.trim();
      final card = entry.value;
      if (uid.isEmpty || card.isEmpty) continue;
      await _users.putUserRaw(uid, card);
      local[uid] = UserSummary.fromMap(uid, card);
    }
    return local;
  }

  UserSummary? peek(
    String uid, {
    bool allowStale = true,
  }) {
    return _users.peekUser(uid, allowStale: allowStale);
  }

  Future<void> seedRaw(
    String uid,
    Map<String, dynamic> raw,
  ) async {
    if (uid.trim().isEmpty || raw.isEmpty) return;
    await _users.putUserRaw(uid, raw);
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
    final nickname = _pickFirstText(<Object?>[
      merged['nickname'],
      merged['username'],
      merged['handle'],
      merged['displayName'],
      merged['authorNickname'],
      merged['authorDisplayName'],
    ]);
    final displayName = _pickFirstText(<Object?>[
      merged['displayName'],
      merged['fullName'],
      merged['authorDisplayName'],
      nickname,
    ]);
    final avatarUrl = resolveAvatarUrl(embedded, profile: profile);
    final rozet = _pickFirstText(<Object?>[
      merged['rozet'],
      merged['badge'],
    ]);
    final token = _pickFirstText(<Object?>[
      merged['token'],
      merged['pushToken'],
    ]);
    return UserSummary(
      userID: normalizedUid,
      displayName: displayName,
      nickname: nickname,
      username: _pickFirstText(<Object?>[
        merged['username'],
        nickname,
      ]),
      avatarUrl: avatarUrl,
      bio: _pickFirstText(<Object?>[
        merged['bio'],
      ]),
      rozet: rozet,
      token: token,
      followerCount:
          _toInt(merged['followerCount'] ?? merged['followersCount']),
      followingCount: _toInt(merged['followingCount']),
      postCount: _toInt(merged['postCount']),
      isPrivate: merged['isPrivate'] == true,
      isDeleted: merged['isDeleted'] == true,
      isApproved: merged['isApproved'] == true,
    );
  }

  String _pickFirstText(List<Object?> candidates) {
    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  int _toInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }
}
