part of 'verified_account_repository.dart';

int _verifiedAccountAsInt(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) return parsed;
    final parsedNum = num.tryParse(value.trim());
    if (parsedNum != null) return parsedNum.toInt();
  }
  return fallback;
}

Future<void> _storeVerifiedAccountStatus(
  VerifiedAccountRepository repository,
  String uid,
  bool exists,
) async {
  final key = _verifiedAccountCacheKey(uid);
  final cachedAt = DateTime.now();
  repository._memory[key] = _CachedVerifiedAccountStatus(
    exists: exists,
    cachedAt: cachedAt,
  );
  repository._prefs ??= await SharedPreferences.getInstance();
  await repository._prefs?.setString(
    _verifiedAccountPrefsKey(repository, key),
    jsonEncode({
      't': cachedAt.millisecondsSinceEpoch,
      'e': exists,
    }),
  );
}

bool? _getVerifiedAccountFromMemory(
  VerifiedAccountRepository repository,
  String key,
) {
  final entry = repository._memory[key];
  if (entry == null) return null;
  if (DateTime.now().difference(entry.cachedAt) >
      VerifiedAccountRepository._ttl) {
    repository._memory.remove(key);
    return null;
  }
  return entry.exists;
}

Future<bool?> _getVerifiedAccountFromPrefs(
  VerifiedAccountRepository repository,
  String key,
) async {
  repository._prefs ??= await SharedPreferences.getInstance();
  final prefs = repository._prefs;
  final prefsKey = _verifiedAccountPrefsKey(repository, key);
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
    final ts = _verifiedAccountAsInt(decoded['t']);
    if (ts <= 0) {
      await prefs?.remove(prefsKey);
      return null;
    }
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
    if (DateTime.now().difference(cachedAt) > VerifiedAccountRepository._ttl) {
      await prefs?.remove(prefsKey);
      return null;
    }
    return decoded['e'] == true;
  } catch (_) {
    await prefs?.remove(prefsKey);
    return null;
  }
}

String _verifiedAccountCacheKey(String uid) => 'verified::$uid';

String _verifiedAccountPrefsKey(
  VerifiedAccountRepository repository,
  String key,
) {
  return '${VerifiedAccountRepository._prefsPrefix}:$key';
}

CollectionReference<Map<String, dynamic>> _verifiedAccountCollection() {
  return FirebaseFirestore.instance
      .collection('adminConfig')
      .doc('admin')
      .collection('TurqAppVerified');
}
