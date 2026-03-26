part of 'top_tags_repository_parts.dart';

extension _TopTagsRepositoryCacheX on TopTagsRepository {
  Future<void> _store(List<HashtagModel> items) async {
    _memory = items.toList(growable: false);
    _memoryAt = DateTime.now();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _topTagsPrefsKey,
      jsonEncode({
        't': _memoryAt!.millisecondsSinceEpoch,
        'items': items
            .map((item) => <String, dynamic>{
                  'hashtag': item.hashtag,
                  'count': item.count,
                  'hasHashtag': item.hasHashtag,
                  'lastSeenTs': item.lastSeenTs,
                })
            .toList(growable: false),
      }),
    );
  }

  List<HashtagModel>? _readMemory({required int limit}) {
    final items = _memory;
    final at = _memoryAt;
    if (items == null || at == null) return null;
    if (DateTime.now().difference(at) > _topTagsTtl) return null;
    return items.take(limit).toList(growable: false);
  }

  Future<List<HashtagModel>?> _readPrefs({required int limit}) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_topTagsPrefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(cachedAt) > _topTagsTtl) {
        return null;
      }
      final items = (decoded['items'] as List?) ?? const [];
      return items
          .map((e) => e as Map)
          .map(
            (e) => HashtagModel(
              (e['hashtag'] ?? '').toString(),
              ((e['count'] ?? 0) as num).toInt(),
              hasHashtag: e['hasHashtag'] == true,
              lastSeenTs: ((e['lastSeenTs'] ?? 0) as num?)?.toInt(),
            ),
          )
          .take(limit)
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  int _resolveLastSeenActivityTs(int rawLastSeenTs, int windowMs, int nowMs) {
    if (rawLastSeenTs <= 0) return 0;
    if (rawLastSeenTs > nowMs) {
      final converted = rawLastSeenTs - windowMs;
      return converted > 0 ? converted : rawLastSeenTs;
    }
    return rawLastSeenTs;
  }

  Future<List<PostsModel>> fetchImagePostsPage({
    int limit = 15,
    bool reset = false,
  }) async {
    if (reset) {
      _feedMemory.clear();
      _lastFeedDoc = null;
    }

    Query<Map<String, dynamic>> query = _db
        .collection('Posts')
        .where('arsiv', isEqualTo: false)
        .where('img', isNotEqualTo: [])
        .where('flood', isEqualTo: false)
        .orderBy('timeStamp', descending: true)
        .limit(limit);

    if (_lastFeedDoc != null) {
      query = query.startAfterDocument(_lastFeedDoc!);
    }

    final snap = await query.get();
    if (snap.docs.isNotEmpty) {
      _lastFeedDoc = snap.docs.last;
      for (final doc in snap.docs) {
        final model = PostsModel.fromFirestore(doc);
        if (model.deletedPost == true) continue;
        _feedMemory.add(model);
      }
    }
    return List<PostsModel>.from(_feedMemory);
  }
}
