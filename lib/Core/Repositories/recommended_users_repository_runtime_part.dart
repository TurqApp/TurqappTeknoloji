part of 'recommended_users_repository.dart';

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
      final raw = _prefs?.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final cachedAtMs = (decoded['cachedAt'] as num?)?.toInt() ?? 0;
      final items = (decoded['items'] as List?) ?? const [];
      if (cachedAtMs <= 0 || items.isEmpty) return;
      final restored = <RecommendedUserModel>[];
      for (final item in items) {
        if (item is! Map) continue;
        final map = item.cast<String, dynamic>();
        final uid = (map['userID'] ?? '').toString().trim();
        if (uid.isEmpty) continue;
        restored.add(RecommendedUserModel.fromMap(uid, map));
      }
      if (restored.isEmpty) return;
      _memory = restored;
      _cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
    } catch (_) {}
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
