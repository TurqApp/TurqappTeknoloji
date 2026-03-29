part of 'practice_exam_repository.dart';

extension PracticeExamRepositoryCachePart on PracticeExamRepository {
  Future<void> _store(String cacheKey, List<SinavModel> items) async {
    final cloned = _cloneItems(items);
    final now = DateTime.now();
    _memory[cacheKey] = _TimedPracticeExams(items: cloned, cachedAt: now);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_practiceExamRepositoryPrefsPrefix:$cacheKey',
      jsonEncode({
        't': now.millisecondsSinceEpoch,
        'items': cloned
            .map((item) => <String, dynamic>{
                  'id': item.docID,
                  'd': <String, dynamic>{
                    'cover': item.cover,
                    'sinavTuru': item.sinavTuru,
                    'timeStamp': item.timeStamp,
                    'sinavAciklama': item.sinavAciklama,
                    'sinavAdi': item.sinavAdi,
                    'kpssSecilenLisans': item.kpssSecilenLisans,
                    'dersler': item.dersler,
                    'taslak': item.taslak,
                    'public': item.public,
                    'userID': item.userID,
                    'soruSayilari': item.soruSayilari,
                    'bitis': item.bitis,
                    'bitisDk': item.bitisDk,
                    'participantCount': item.participantCount,
                  },
                })
            .toList(growable: false),
      }),
    );
  }

  Future<void> _storeRawDoc(String cacheKey, Map<String, dynamic> data) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_practiceExamRepositoryPrefsPrefix:$cacheKey',
      jsonEncode({
        't': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }),
    );
  }

  Future<void> _storeRawList(
    String cacheKey,
    List<Map<String, dynamic>> data,
  ) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_practiceExamRepositoryPrefsPrefix:$cacheKey',
      jsonEncode({
        't': DateTime.now().millisecondsSinceEpoch,
        'items': data,
      }),
    );
  }

  List<SinavModel>? _getFromMemory(String cacheKey) {
    final entry = _memory[cacheKey];
    if (entry == null) return null;
    final fresh =
        DateTime.now().difference(entry.cachedAt) <= _practiceExamRepositoryTtl;
    if (!fresh) {
      _memory.remove(cacheKey);
      return null;
    }
    return _cloneItems(entry.items);
  }

  Future<List<SinavModel>?> _getFromPrefs(String cacheKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final prefsKey = '$_practiceExamRepositoryPrefsPrefix:$cacheKey';
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
      if (ts <= 0) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final fresh =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) <=
              _practiceExamRepositoryTtl;
      if (!fresh) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final items = (decoded['items'] as List?) ?? const [];
      return items
          .map((e) => e as Map)
          .map(
            (e) => _fromDoc(
              (e['id'] ?? '').toString(),
              Map<String, dynamic>.from((e['d'] as Map?) ?? const {}),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getRawDoc(String cacheKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final prefsKey = '$_practiceExamRepositoryPrefsPrefix:$cacheKey';
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
      if (ts <= 0) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final fresh =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) <=
              _practiceExamRepositoryTtl;
      if (!fresh) {
        await prefs?.remove(prefsKey);
        return null;
      }
      return Map<String, dynamic>.from(
        (decoded['data'] as Map?) ?? const <String, dynamic>{},
      );
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> _getRawList(String cacheKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final prefsKey = '$_practiceExamRepositoryPrefsPrefix:$cacheKey';
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
      if (ts <= 0) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final fresh =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) <=
              _practiceExamRepositoryTtl;
      if (!fresh) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final items = (decoded['items'] as List?) ?? const [];
      return items
          .map((item) => Map<String, dynamic>.from((item as Map?) ?? const {}))
          .toList(growable: false);
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  List<SinavModel> _cloneItems(List<SinavModel> items) {
    return items.map(_cloneItem).toList(growable: false);
  }

  SinavModel _cloneItem(SinavModel item) {
    return SinavModel(
      docID: item.docID,
      cover: item.cover,
      sinavTuru: item.sinavTuru,
      timeStamp: item.timeStamp,
      sinavAciklama: item.sinavAciklama,
      sinavAdi: item.sinavAdi,
      kpssSecilenLisans: item.kpssSecilenLisans,
      dersler: List<String>.from(item.dersler),
      taslak: item.taslak,
      public: item.public,
      userID: item.userID,
      soruSayilari: List<String>.from(item.soruSayilari),
      bitis: item.bitis,
      bitisDk: item.bitisDk,
      participantCount: item.participantCount,
      shortId: item.shortId,
      shortUrl: item.shortUrl,
    );
  }
}
