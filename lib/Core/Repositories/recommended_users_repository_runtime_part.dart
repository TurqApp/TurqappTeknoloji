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
  }) =>
      _fetchCandidatesImpl(limit: limit, preferCache: preferCache);
}

extension RecommendedUsersRepositoryRuntimePart on RecommendedUsersRepository {
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _restoreFromPrefs();
    _authSub ??= FirebaseAuth.instance.authStateChanges().listen((_) {
      _memory = const <RecommendedUserModel>[];
      _cachedAt = null;
      _restoreFromPrefs();
    });
    _initialized = true;
  }

  Future<List<RecommendedUserModel>> _fetchCandidatesImpl({
    required int limit,
    required bool preferCache,
  }) async {
    await _ensureInitialized();

    if (preferCache && _isFresh && _memory.length >= limit) {
      return List<RecommendedUserModel>.from(_memory.take(limit));
    }

    if (preferCache && _isFresh && _memory.isNotEmpty) {
      return List<RecommendedUserModel>.from(_memory.take(limit));
    }

    final snap = await FirebaseFirestore.instance
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
      final cachedAtMs = (decoded['cachedAt'] as num?)?.toInt() ?? 0;
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

  void _handleClose() {
    _authSub?.cancel();
  }
}
