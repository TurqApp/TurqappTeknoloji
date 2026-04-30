part of 'recommended_users_repository.dart';

class RecommendedUsersRepository extends GetxService {
  static const String _prefsKeyPrefix = 'recommended_users_repository_v1';
  static const Duration _ttl = Duration(minutes: 10);
  final _state = _RecommendedUsersRepositoryState();

  @override
  void onClose() {
    _handleClose();
    super.onClose();
  }
}

class _RecommendedUsersRepositoryState {
  List<RecommendedUserModel> memory = const <RecommendedUserModel>[];
  DateTime? cachedAt;
  SharedPreferences? prefs;
  bool initialized = false;
  StreamSubscription<User?>? authSub;
}

extension RecommendedUsersRepositoryFieldsPart on RecommendedUsersRepository {
  List<RecommendedUserModel> get _memory => _state.memory;
  set _memory(List<RecommendedUserModel> value) => _state.memory = value;

  DateTime? get _cachedAt => _state.cachedAt;
  set _cachedAt(DateTime? value) => _state.cachedAt = value;

  SharedPreferences? get _prefs => _state.prefs;
  set _prefs(SharedPreferences? value) => _state.prefs = value;

  bool get _initialized => _state.initialized;
  set _initialized(bool value) => _state.initialized = value;

  StreamSubscription<User?>? get _authSub => _state.authSub;
  set _authSub(StreamSubscription<User?>? value) => _state.authSub = value;

  String get _prefsKey =>
      userScopedKey(RecommendedUsersRepository._prefsKeyPrefix);

  bool get _isFresh =>
      _cachedAt != null &&
      DateTime.now().difference(_cachedAt!) <= RecommendedUsersRepository._ttl;
}

RecommendedUsersRepository? maybeFindRecommendedUsersRepository() {
  final isRegistered = Get.isRegistered<RecommendedUsersRepository>();
  if (!isRegistered) return null;
  return Get.find<RecommendedUsersRepository>();
}

RecommendedUsersRepository ensureRecommendedUsersRepository() {
  final existing = maybeFindRecommendedUsersRepository();
  if (existing != null) return existing;
  return Get.put(RecommendedUsersRepository(), permanent: true);
}

extension RecommendedUsersRepositoryFacadePart on RecommendedUsersRepository {
  Future<List<RecommendedUserModel>> fetchCandidates({
    int limit = 500,
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      _fetchCandidatesImpl(
        limit: limit,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<List<RecommendedUserModel>> loadCachedCandidates({
    int limit = 500,
    bool allowStale = false,
  }) =>
      _loadCachedCandidatesImpl(limit: limit, allowStale: allowStale);

  Future<void> invalidate() => _invalidateImpl();
}

extension RecommendedUsersRepositoryRuntimePart on RecommendedUsersRepository {
  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
      final parsedNum = num.tryParse(value.trim());
      if (parsedNum != null) return parsedNum.toInt();
    }
    return fallback;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _prefs = await ensureLocalPreferenceRepository().sharedPreferences();
    _restoreFromPrefs();
    _authSub ??= AppFirebaseAuth.instance.authStateChanges().listen((_) {
      _memory = const <RecommendedUserModel>[];
      _cachedAt = null;
      _restoreFromPrefs();
    });
    _initialized = true;
  }

  Future<List<RecommendedUserModel>> _fetchCandidatesImpl({
    required int limit,
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    await _ensureInitialized();

    if (cacheOnly) {
      return _loadCachedCandidatesImpl(limit: limit, allowStale: true);
    }

    if (preferCache && _isFresh && _memory.length >= limit) {
      return List<RecommendedUserModel>.from(_memory.take(limit));
    }

    if (preferCache && _isFresh && _memory.isNotEmpty) {
      return List<RecommendedUserModel>.from(_memory.take(limit));
    }

    final snap = await AppFirestore.instance
        .collection('users')
        .where('isPrivate', isEqualTo: false)
        .limit(limit)
        .get(const GetOptions(source: Source.serverAndCache));

    final fetched = snap.docs
        .map(RecommendedUserModel.fromDocument)
        .toList(growable: false);
    _memory = fetched;
    _cachedAt = DateTime.now();
    await _persistToPrefs();
    return List<RecommendedUserModel>.from(fetched);
  }

  Future<List<RecommendedUserModel>> _loadCachedCandidatesImpl({
    required int limit,
    required bool allowStale,
  }) async {
    await _ensureInitialized();
    if (_memory.isEmpty) {
      return const <RecommendedUserModel>[];
    }
    if (!_isFresh && !allowStale) {
      return const <RecommendedUserModel>[];
    }
    return List<RecommendedUserModel>.from(_memory.take(limit));
  }

  void _restoreFromPrefs() {
    try {
      final prefs = _prefs;
      final raw = _prefs?.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        prefs?.remove(_prefsKey);
        return;
      }
      final cachedAtMs = _asInt(decoded['cachedAt']);
      final items = (decoded['items'] as List?) ?? const [];
      if (cachedAtMs <= 0 || items.isEmpty) {
        prefs?.remove(_prefsKey);
        return;
      }
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
      if (DateTime.now().difference(cachedAt) >
          RecommendedUsersRepository._ttl) {
        prefs?.remove(_prefsKey);
        return;
      }
      final restored = <RecommendedUserModel>[];
      for (final item in items) {
        if (item is! Map) continue;
        final map = item.cast<String, dynamic>();
        final uid = (map['userID'] ?? '').toString().trim();
        if (uid.isEmpty) continue;
        restored.add(RecommendedUserModel.fromMap(uid, map));
      }
      if (restored.isEmpty) {
        prefs?.remove(_prefsKey);
        return;
      }
      _memory = restored;
      _cachedAt = cachedAt;
    } catch (_) {
      _prefs?.remove(_prefsKey);
    }
  }

  Future<void> _persistToPrefs() async {
    try {
      await _prefs?.setString(
        _prefsKey,
        jsonEncode({
          'cachedAt': _cachedAt?.millisecondsSinceEpoch ?? 0,
          'items': _memory.map((e) => e.toMap()).toList(),
        }),
      );
    } catch (_) {}
  }

  Future<void> _invalidateImpl() async {
    await _ensureInitialized();
    _memory = const <RecommendedUserModel>[];
    _cachedAt = null;
    try {
      await _prefs?.remove(_prefsKey);
    } catch (_) {}
  }

  void _handleClose() {
    _authSub?.cancel();
  }
}
