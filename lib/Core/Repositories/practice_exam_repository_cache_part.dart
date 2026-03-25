part of 'practice_exam_repository.dart';

extension PracticeExamRepositoryCachePart on PracticeExamRepository {
  Future<void> _store(String cacheKey, List<SinavModel> items) async {
    final cloned = items.toList(growable: false);
    final now = DateTime.now();
    _memory[cacheKey] = _TimedPracticeExams(items: cloned, cachedAt: now);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '${PracticeExamRepository._prefsPrefix}:$cacheKey',
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
      '${PracticeExamRepository._prefsPrefix}:$cacheKey',
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
      '${PracticeExamRepository._prefsPrefix}:$cacheKey',
      jsonEncode({
        't': DateTime.now().millisecondsSinceEpoch,
        'items': data,
      }),
    );
  }

  List<SinavModel>? _getFromMemory(String cacheKey) {
    final entry = _memory[cacheKey];
    if (entry == null) return null;
    final fresh = DateTime.now().difference(entry.cachedAt) <=
        PracticeExamRepository._ttl;
    if (!fresh) return null;
    return entry.items.toList(growable: false);
  }

  Future<List<SinavModel>?> _getFromPrefs(String cacheKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw =
        _prefs?.getString('${PracticeExamRepository._prefsPrefix}:$cacheKey');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) return null;
      final fresh =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) <=
              PracticeExamRepository._ttl;
      if (!fresh) return null;
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
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getRawDoc(String cacheKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw =
        _prefs?.getString('${PracticeExamRepository._prefsPrefix}:$cacheKey');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) return null;
      final fresh =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) <=
              PracticeExamRepository._ttl;
      if (!fresh) return null;
      return Map<String, dynamic>.from(
        (decoded['data'] as Map?) ?? const <String, dynamic>{},
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> _getRawList(String cacheKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw =
        _prefs?.getString('${PracticeExamRepository._prefsPrefix}:$cacheKey');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) return null;
      final fresh =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) <=
              PracticeExamRepository._ttl;
      if (!fresh) return null;
      final items = (decoded['items'] as List?) ?? const [];
      return items
          .map((item) => Map<String, dynamic>.from((item as Map?) ?? const {}))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }
}
