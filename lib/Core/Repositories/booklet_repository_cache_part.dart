part of 'booklet_repository.dart';

extension BookletRepositoryCachePart on BookletRepository {
  void _handleBookletRepositoryInit() {
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  Future<void> _store(String cacheKey, List<BookletModel> items) async {
    final cloned = items.toList(growable: false);
    final now = DateTime.now();
    _memory[cacheKey] = _TimedBooklets(items: cloned, cachedAt: now);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '${BookletRepository._prefsPrefix}:$cacheKey',
      jsonEncode({
        't': now.millisecondsSinceEpoch,
        'items': cloned
            .map((item) => <String, dynamic>{
                  'id': item.docID,
                  'd': <String, dynamic>{
                    'dil': item.dil,
                    'sinavTuru': item.sinavTuru,
                    'cover': item.cover,
                    'baslik': item.baslik,
                    'timeStamp': item.timeStamp,
                    'kaydet': item.kaydet,
                    'basimTarihi': item.basimTarihi,
                    'yayinEvi': item.yayinEvi,
                    'userID': item.userID,
                    'viewCount': item.viewCount,
                  },
                })
            .toList(growable: false),
      }),
    );
  }

  Future<void> _storeRawList(
    String cacheKey,
    List<Map<String, dynamic>> items,
  ) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '${BookletRepository._prefsPrefix}:$cacheKey',
      jsonEncode({
        't': DateTime.now().millisecondsSinceEpoch,
        'items': items,
      }),
    );
  }

  List<BookletModel>? _getFromMemory(String cacheKey) {
    final entry = _memory[cacheKey];
    if (entry == null) return null;
    final fresh =
        DateTime.now().difference(entry.cachedAt) <= BookletRepository._ttl;
    if (!fresh) return null;
    return entry.items.toList(growable: false);
  }

  Future<List<BookletModel>?> _getFromPrefs(String cacheKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw =
        _prefs?.getString('${BookletRepository._prefsPrefix}:$cacheKey');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) return null;
      final fresh =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) <=
              BookletRepository._ttl;
      if (!fresh) return null;
      final items = (decoded['items'] as List?) ?? const [];
      return items
          .map((e) => e as Map)
          .map(
            (e) => BookletModel.fromMap(
              Map<String, dynamic>.from((e['d'] as Map?) ?? const {}),
              (e['id'] ?? '').toString(),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> _readRawList(String cacheKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw =
        _prefs?.getString('${BookletRepository._prefsPrefix}:$cacheKey');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) return null;
      final fresh =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) <=
              BookletRepository._ttl;
      if (!fresh) return null;
      return ((decoded['items'] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from((e as Map)))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }
}
