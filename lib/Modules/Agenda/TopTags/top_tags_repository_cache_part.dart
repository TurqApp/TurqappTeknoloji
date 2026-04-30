part of 'top_tags_repository_parts.dart';

extension _TopTagsRepositoryCacheX on TopTagsRepository {
  Future<void> _store(List<HashtagModel> items) async {
    _memory = items.toList(growable: false);
    _memoryAt = DateTime.now();
    final preferences = _preferences ??= ensureLocalPreferenceRepository();
    await preferences.setString(
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
    final preferences = _preferences ??= ensureLocalPreferenceRepository();
    final raw = await preferences.getString(_topTagsPrefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decodedRaw = jsonDecode(raw);
      if (decodedRaw is! Map<String, dynamic>) {
        await preferences.remove(_topTagsPrefsKey);
        return null;
      }
      final decoded = decodedRaw;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) {
        await preferences.remove(_topTagsPrefsKey);
        return null;
      }
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(cachedAt) > _topTagsTtl) {
        await preferences.remove(_topTagsPrefsKey);
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
      await preferences.remove(_topTagsPrefsKey);
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
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (reset) {
      _feedMemory.clear();
      _lastFeedDoc = null;
    }

    Query<Map<String, dynamic>> query = _db
        .collection('Posts')
        .where('arsiv', isEqualTo: false)
        .where('img', isNotEqualTo: [])
        .where('flood', isEqualTo: false)
        .where('timeStamp', isLessThanOrEqualTo: nowMs)
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
        if (model.timeStamp > nowMs) continue;
        _feedMemory.add(model);
      }
    }
    return List<PostsModel>.from(_feedMemory);
  }
}
