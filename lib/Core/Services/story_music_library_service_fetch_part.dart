part of 'story_music_library_service.dart';

extension StoryMusicLibraryServiceFetchPart on StoryMusicLibraryService {
  Future<List<MusicModel>> fetchTracks({
    int limit = 20,
    bool forceRemote = false,
  }) async {
    if (!forceRemote) {
      final cached = await _loadCache();
      if (cached.isNotEmpty) {
        unawaited(_warmTopCache(limit: 100));
        return _sortAndLimit(cached, limit);
      }
    }

    final remote = await _fetchRemote();
    if (remote.isNotEmpty) {
      await _persistCache(remote);
      unawaited(_warmTopCache(limit: 100));
      return _sortAndLimit(remote, limit);
    }

    final cached = await _loadCache(ignoreTtl: true);
    if (cached.isNotEmpty) {
      unawaited(_warmTopCache(limit: 100));
      return _sortAndLimit(cached, limit);
    }

    return const <MusicModel>[];
  }

  Future<List<MusicModel>> fetchAdminTracks({
    bool preferCache = true,
    bool forceRemote = false,
  }) async {
    if (preferCache && !forceRemote) {
      final cached = await _loadCache(ignoreTtl: true);
      if (cached.isNotEmpty) {
        return cached.toList(growable: true)
          ..sort((a, b) {
            final byOrder = a.order.compareTo(b.order);
            if (byOrder != 0) return byOrder;
            return compareNormalizedText(a.title, b.title);
          });
      }
    }

    try {
      final snap = await _collection.orderBy('order').get();
      final items = snap.docs
          .map((doc) => MusicModel.fromMap(doc.data(), doc.id))
          .toList(growable: true);
      if (items.isNotEmpty) {
        await _persistCache(items);
      }
      return items;
    } catch (_) {
      final cached = await _loadCache(ignoreTtl: true);
      return cached.toList(growable: true)
        ..sort((a, b) {
          final byOrder = a.order.compareTo(b.order);
          if (byOrder != 0) return byOrder;
          return compareNormalizedText(a.title, b.title);
        });
    }
  }

  Future<int> fetchNextOrder() async {
    try {
      final tracks = await fetchAdminTracks(preferCache: true);
      if (tracks.isEmpty) return 1;
      return tracks
              .map((e) => e.order)
              .fold<int>(0, (max, value) => value > max ? value : max) +
          1;
    } catch (_) {
      return 1;
    }
  }

  Future<MusicModel?> fetchTrackById(
    String musicId, {
    bool preferCache = true,
  }) async {
    final cleanId = musicId.trim();
    if (cleanId.isEmpty) return null;

    if (preferCache) {
      final cached = await _loadCache(ignoreTtl: true);
      for (final track in cached) {
        if (track.docID == cleanId) {
          return track;
        }
      }
    }

    try {
      final doc = await _collection.doc(cleanId).get();
      if (!doc.exists) return null;
      return MusicModel.fromMap(
        doc.data() ?? const <String, dynamic>{},
        doc.id,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchStoryLinks(
    String musicId, {
    int limit = 50,
  }) async {
    final cleanId = musicId.trim();
    if (cleanId.isEmpty) return const [];
    try {
      final snap = await _collection
          .doc(cleanId)
          .collection('stories')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs;
    } catch (_) {
      return const [];
    }
  }

  Future<Set<String>> fetchSavedMusicIds() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return <String>{};
    try {
      final entries = await _userSubcollectionRepository.getEntries(
        uid,
        subcollection: 'savedMusic',
        orderByField: 'savedAt',
        descending: true,
        preferCache: true,
      );
      return entries.map((entry) => entry.id).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<List<MusicModel>> _fetchRemote() async {
    try {
      final snap = await _collection.limit(200).get();
      return snap.docs
          .map((doc) => MusicModel.fromMap(doc.data(), doc.id))
          .where((track) => track.isActive && track.audioUrl.isNotEmpty)
          .toList(growable: true);
    } catch (_) {
      return const <MusicModel>[];
    }
  }

  Future<List<MusicModel>> _loadCache({bool ignoreTtl = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = StoryMusicLibraryService._cacheKey;
      final cacheTimeKey = StoryMusicLibraryService._cacheTimeKey;
      if (!ignoreTtl) {
        final updatedAt = prefs.getInt(cacheTimeKey) ?? 0;
        if (updatedAt <= 0) return const <MusicModel>[];
        final age = DateTime.now().millisecondsSinceEpoch - updatedAt;
        if (age > StoryMusicLibraryService._cacheTtl.inMilliseconds) {
          await prefs.remove(cacheKey);
          await prefs.remove(cacheTimeKey);
          return const <MusicModel>[];
        }
      }

      final raw = prefs.getString(cacheKey);
      if (raw == null || raw.isEmpty) return const <MusicModel>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        await prefs.remove(cacheKey);
        await prefs.remove(cacheTimeKey);
        return const <MusicModel>[];
      }
      return decoded
          .whereType<Map>()
          .map((e) => MusicModel.fromCacheMap(Map<String, dynamic>.from(e)))
          .where((track) => track.isActive && track.audioUrl.isNotEmpty)
          .toList(growable: true);
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(StoryMusicLibraryService._cacheKey);
        await prefs.remove(StoryMusicLibraryService._cacheTimeKey);
      } catch (_) {}
      return const <MusicModel>[];
    }
  }

  Future<void> _persistCache(List<MusicModel> tracks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        StoryMusicLibraryService._cacheKey,
        jsonEncode(tracks.map((e) => e.toCacheMap()).toList()),
      );
      await prefs.setInt(
        StoryMusicLibraryService._cacheTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  List<MusicModel> _sortAndLimit(List<MusicModel> tracks, int limit) {
    final sorted = tracks.toList(growable: true)
      ..sort((a, b) {
        final byUse = b.useCount.compareTo(a.useCount);
        if (byUse != 0) return byUse;
        final byOrder = a.order.compareTo(b.order);
        if (byOrder != 0) return byOrder;
        return compareNormalizedText(a.title, b.title);
      });
    if (sorted.length <= limit) return sorted;
    return sorted.take(limit).toList(growable: false);
  }
}
