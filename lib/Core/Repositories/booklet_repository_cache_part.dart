part of 'booklet_repository.dart';

class BookletPage {
  const BookletPage({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<BookletModel> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
}

class _TimedBooklets {
  const _TimedBooklets({required this.items, required this.cachedAt});

  final List<BookletModel> items;
  final DateTime cachedAt;
}

class BookletRepository extends GetxService {
  BookletRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'booklet_repository_v1';
  final Map<String, _TimedBooklets> _memory = <String, _TimedBooklets>{};
  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _handleBookletRepositoryInit();
  }
}

BookletRepository? maybeFindBookletRepository() {
  final isRegistered = Get.isRegistered<BookletRepository>();
  if (!isRegistered) return null;
  return Get.find<BookletRepository>();
}

BookletRepository ensureBookletRepository() {
  final existing = maybeFindBookletRepository();
  if (existing != null) return existing;
  return Get.put(BookletRepository(), permanent: true);
}

extension BookletRepositoryCachePart on BookletRepository {
  void _handleBookletRepositoryInit() {
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  Future<void> _store(String cacheKey, List<BookletModel> items) async {
    final cloned = _cloneItems(items);
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
        'items': _cloneRawItems(items),
      }),
    );
  }

  List<BookletModel>? _getFromMemory(String cacheKey) {
    final entry = _memory[cacheKey];
    if (entry == null) return null;
    final fresh =
        DateTime.now().difference(entry.cachedAt) <= BookletRepository._ttl;
    if (!fresh) {
      _memory.remove(cacheKey);
      return null;
    }
    return _cloneItems(entry.items);
  }

  Future<List<BookletModel>?> _getFromPrefs(String cacheKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final prefsKey = '${BookletRepository._prefsPrefix}:$cacheKey';
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
              BookletRepository._ttl;
      if (!fresh) {
        await prefs?.remove(prefsKey);
        return null;
      }
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
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> _readRawList(String cacheKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final prefsKey = '${BookletRepository._prefsPrefix}:$cacheKey';
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
              BookletRepository._ttl;
      if (!fresh) {
        await prefs?.remove(prefsKey);
        return null;
      }
      return _cloneRawItems(
        ((decoded['items'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from((e as Map)))
            .toList(growable: false),
      );
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  List<BookletModel> _cloneItems(List<BookletModel> items) {
    return items.map(_cloneItem).toList(growable: false);
  }

  BookletModel _cloneItem(BookletModel item) {
    return BookletModel(
      dil: item.dil,
      sinavTuru: item.sinavTuru,
      cover: item.cover,
      baslik: item.baslik,
      timeStamp: item.timeStamp,
      docID: item.docID,
      kaydet: List<String>.from(item.kaydet),
      basimTarihi: item.basimTarihi,
      yayinEvi: item.yayinEvi,
      userID: item.userID,
      viewCount: item.viewCount,
      shortId: item.shortId,
      shortUrl: item.shortUrl,
    );
  }

  List<Map<String, dynamic>> _cloneRawItems(List<Map<String, dynamic>> items) {
    return items.map(_cloneRawItem).toList(growable: false);
  }

  Map<String, dynamic> _cloneRawItem(Map<String, dynamic> item) {
    return item.map((key, value) => MapEntry(key, _cloneRawValue(value)));
  }

  dynamic _cloneRawValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, child) => MapEntry(key.toString(), _cloneRawValue(child)),
      );
    }
    if (value is List) {
      return value.map(_cloneRawValue).toList(growable: false);
    }
    return value;
  }
}
