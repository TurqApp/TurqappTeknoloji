part of 'test_repository_parts.dart';

extension _TestRepositoryCacheX on TestRepository {
  TestsModel _fromDoc(String id, Map<String, dynamic> data) {
    return TestsModel(
      userID: (data['userID'] ?? '').toString(),
      timeStamp: (data['timeStamp'] ?? '').toString(),
      aciklama: (data['aciklama'] ?? '').toString(),
      dersler: (data['dersler'] is List)
          ? (data['dersler'] as List).map((e) => e.toString()).toList()
          : <String>[],
      img: (data['img'] ?? '').toString(),
      docID: id,
      paylasilabilir: data['paylasilabilir'] == true,
      testTuru: (data['testTuru'] ?? '').toString(),
      taslak: data['taslak'] == true,
    );
  }

  Future<void> _store(String cacheKey, List<TestsModel> items) async {
    final cloned = items.toList(growable: false);
    final now = DateTime.now();
    _memory[cacheKey] = _TimedTests(items: cloned, cachedAt: now);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '${TestRepository._prefsPrefix}:$cacheKey',
      jsonEncode({
        't': now.millisecondsSinceEpoch,
        'items': cloned
            .map((item) => <String, dynamic>{
                  'id': item.docID,
                  'd': <String, dynamic>{
                    'userID': item.userID,
                    'timeStamp': item.timeStamp,
                    'aciklama': item.aciklama,
                    'dersler': item.dersler,
                    'img': item.img,
                    'paylasilabilir': item.paylasilabilir,
                    'testTuru': item.testTuru,
                    'taslak': item.taslak,
                  },
                })
            .toList(growable: false),
      }),
    );
  }

  Future<void> _storeRawDoc(String cacheKey, Map<String, dynamic> data) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '${TestRepository._prefsPrefix}:$cacheKey',
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
      '${TestRepository._prefsPrefix}:$cacheKey',
      jsonEncode({
        't': DateTime.now().millisecondsSinceEpoch,
        'items': data,
      }),
    );
  }

  Future<List<Map<String, dynamic>>?> _getRawList(String cacheKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final prefsKey = '${TestRepository._prefsPrefix}:$cacheKey';
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
              TestRepository._ttl;
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

  Future<Map<String, dynamic>?> _getRawDoc(String cacheKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final prefsKey = '${TestRepository._prefsPrefix}:$cacheKey';
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
              TestRepository._ttl;
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

  List<TestsModel>? _getFromMemory(String cacheKey) {
    final entry = _memory[cacheKey];
    if (entry == null) return null;
    final fresh =
        DateTime.now().difference(entry.cachedAt) <= TestRepository._ttl;
    if (!fresh) {
      _memory.remove(cacheKey);
      return null;
    }
    return entry.items.toList(growable: false);
  }

  Future<_TimedTests?> _getTimedFromPrefs(String cacheKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final prefsKey = '${TestRepository._prefsPrefix}:$cacheKey';
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
              TestRepository._ttl;
      if (!fresh) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final items = (decoded['items'] as List?) ?? const [];
      return _TimedTests(
        items: items
            .map((e) => e as Map)
            .map(
              (e) => _fromDoc(
                (e['id'] ?? '').toString(),
                Map<String, dynamic>.from((e['d'] as Map?) ?? const {}),
              ),
            )
            .toList(growable: false),
        cachedAt: DateTime.fromMillisecondsSinceEpoch(ts),
      );
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  List<List<String>> _chunkIds(List<String> ids, int size) {
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += size) {
      final end = (i + size < ids.length) ? i + size : ids.length;
      chunks.add(ids.sublist(i, end));
    }
    return chunks;
  }

  TestReadinessModel? _questionFromMap(Map<String, dynamic> raw) {
    final docId = (raw['_docId'] ?? '').toString();
    if (docId.isEmpty) return null;
    final id = raw['id'] is num
        ? raw['id'] as num
        : num.tryParse((raw['id'] ?? '0').toString()) ?? 0;
    return TestReadinessModel(
      id: id,
      img: (raw['img'] ?? '').toString(),
      max: (raw['max'] ?? 0) as num,
      dogruCevap: (raw['dogruCevap'] ?? '').toString(),
      docID: docId,
    );
  }
}
