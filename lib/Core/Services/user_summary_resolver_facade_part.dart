part of 'user_summary_resolver.dart';

UserSummaryResolver? _maybeFindUserSummaryResolver() =>
    Get.isRegistered<UserSummaryResolver>()
        ? Get.find<UserSummaryResolver>()
        : null;

UserSummaryResolver _ensureUserSummaryResolver() =>
    _maybeFindUserSummaryResolver() ??
    Get.put(UserSummaryResolver(), permanent: true);

extension UserSummaryResolverFacadePart on UserSummaryResolver {
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
    final raw = await _users.getPublicUserRaw(
      uid,
      preferCache: false,
      cacheOnly: cacheOnly,
      forceServer: true,
    );
    if (raw == null || raw.isEmpty) return null;
    return UserSummary.fromMap(uid.trim(), raw);
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
}
