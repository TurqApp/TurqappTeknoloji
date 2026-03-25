part of 'verified_account_repository.dart';

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
    return null;
  }
  return entry.exists;
}

Future<bool?> _getVerifiedAccountFromPrefs(
  VerifiedAccountRepository repository,
  String key,
) async {
  repository._prefs ??= await SharedPreferences.getInstance();
  final raw =
      repository._prefs?.getString(_verifiedAccountPrefsKey(repository, key));
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final ts = (decoded['t'] as num?)?.toInt() ?? 0;
    if (ts <= 0) return null;
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
    if (DateTime.now().difference(cachedAt) > VerifiedAccountRepository._ttl) {
      return null;
    }
    return decoded['e'] == true;
  } catch (_) {
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
