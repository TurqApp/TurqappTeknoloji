part of 'user_subdoc_repository.dart';

Future<void> _putUserSubdoc(
  UserSubdocRepository repository,
  String uid, {
  required String collection,
  required String docId,
  required Map<String, dynamic> data,
}) async {
  if (uid.isEmpty || collection.isEmpty || docId.isEmpty) return;
  final key = _userSubdocCacheKey(uid, collection, docId);
  final cachedAt = DateTime.now();
  repository._memory[key] = _CachedUserSubdoc(
    data: Map<String, dynamic>.from(data),
    cachedAt: cachedAt,
  );
  repository._prefs ??= await SharedPreferences.getInstance();
  await repository._prefs?.setString(
    _userSubdocPrefsKey(key),
    jsonEncode({
      't': cachedAt.millisecondsSinceEpoch,
      'd': data,
    }),
  );
}

Map<String, dynamic>? _getUserSubdocFromMemory(
  UserSubdocRepository repository,
  String key, {
  required Duration ttl,
}) {
  final entry = repository._memory[key];
  if (entry == null) return null;
  if (DateTime.now().difference(entry.cachedAt) > ttl) return null;
  return Map<String, dynamic>.from(entry.data);
}

Future<Map<String, dynamic>?> _getUserSubdocFromPrefs(
  UserSubdocRepository repository,
  String key, {
  required Duration ttl,
}) async {
  repository._prefs ??= await SharedPreferences.getInstance();
  final prefs = repository._prefs;
  final prefsKey = _userSubdocPrefsKey(key);
  final raw = prefs?.getString(prefsKey);
  if (raw == null || raw.isEmpty) return null;
  try {
    final decodedRaw = jsonDecode(raw);
    if (decodedRaw is! Map) {
      await prefs?.remove(prefsKey);
      return null;
    }
    final decoded = Map<String, dynamic>.from(
      decodedRaw.cast<dynamic, dynamic>(),
    );
    final ts = (decoded['t'] as num?)?.toInt() ?? 0;
    final data = (decoded['d'] as Map?)?.cast<String, dynamic>();
    if (ts <= 0 || data == null) {
      await prefs?.remove(prefsKey);
      return null;
    }
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
    if (DateTime.now().difference(cachedAt) > ttl) {
      await prefs?.remove(prefsKey);
      return null;
    }
    return data;
  } catch (_) {
    await prefs?.remove(prefsKey);
    return null;
  }
}

Future<void> _invalidateUserSubdoc(
  UserSubdocRepository repository,
  String uid, {
  required String collection,
  required String docId,
}) async {
  final key = _userSubdocCacheKey(uid, collection, docId);
  repository._memory.remove(key);
  repository._prefs ??= await SharedPreferences.getInstance();
  await repository._prefs?.remove(_userSubdocPrefsKey(key));
}

String _userSubdocCacheKey(String uid, String collection, String docId) =>
    '$uid::$collection::$docId';

String _userSubdocPrefsKey(String key) =>
    '${UserSubdocRepository._prefsPrefix}:$key';
