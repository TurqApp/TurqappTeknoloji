part of 'story_music_library_service.dart';

extension StoryMusicLibraryServiceActionPart on StoryMusicLibraryService {
  Future<void> saveAdminTrack({
    required String docId,
    required String title,
    required String artist,
    required String audioUrl,
    required String coverUrl,
    required int durationMs,
    required int useCount,
    required int shareCount,
    required int storyCount,
    required int order,
    required bool isActive,
    required String category,
    required int lastUsedAt,
    required int createdAt,
    required int updatedAt,
  }) async {
    final cleanId = docId.trim();
    if (cleanId.isEmpty) return;

    await _collection.doc(cleanId).set({
      'title': title,
      'artist': artist,
      'audioUrl': audioUrl,
      'coverUrl': coverUrl,
      'durationMs': durationMs,
      'useCount': useCount,
      'shareCount': shareCount,
      'storyCount': storyCount,
      'order': order,
      'isActive': isActive,
      'category': category,
      'lastUsedAt': lastUsedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    }, SetOptions(merge: true));

    final cached = await _loadCache(ignoreTtl: true);
    final nextTrack = MusicModel(
      docID: cleanId,
      title: title,
      artist: artist,
      audioUrl: audioUrl,
      coverUrl: coverUrl,
      durationMs: durationMs,
      useCount: useCount,
      shareCount: shareCount,
      storyCount: storyCount,
      order: order,
      lastUsedAt: lastUsedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
      category: category,
    );
    final next = cached.toList(growable: true)
      ..removeWhere((track) => track.docID == cleanId)
      ..add(nextTrack)
      ..sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        if (byOrder != 0) return byOrder;
        return compareNormalizedText(a.title, b.title);
      });
    await _persistCache(next);
  }

  Future<void> deleteAdminTrack(String docId) async {
    final cleanId = docId.trim();
    if (cleanId.isEmpty) return;

    await _collection.doc(cleanId).delete();

    final cached = await _loadCache(ignoreTtl: true);
    if (cached.isEmpty) return;
    final next =
        cached.where((track) => track.docID != cleanId).toList(growable: false);
    await _persistCache(next);
  }

  Future<void> incrementUseCount(MusicModel track) async {
    if (track.docID.trim().isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await _collection.doc(track.docID).set({
        'title': track.title,
        'artist': track.artist,
        'audioUrl': track.audioUrl,
        'coverUrl': track.coverUrl,
        'durationMs': track.durationMs,
        'category': track.category,
        'order': track.order,
        'isActive': true,
        'useCount': FieldValue.increment(1),
        'shareCount': track.shareCount,
        'storyCount': track.storyCount,
        'lastUsedAt': now,
      }, SetOptions(merge: true));
    } catch (_) {}

    final cached = await _loadCache(ignoreTtl: true);
    if (cached.isEmpty) return;
    final index = cached.indexWhere((e) => e.docID == track.docID);
    if (index == -1) return;
    final current = cached[index];
    cached[index] = MusicModel(
      docID: current.docID,
      title: current.title,
      artist: current.artist,
      audioUrl: current.audioUrl,
      coverUrl: current.coverUrl,
      durationMs: current.durationMs,
      useCount: current.useCount + 1,
      shareCount: current.shareCount,
      storyCount: current.storyCount,
      order: current.order,
      lastUsedAt: now,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
      isActive: current.isActive,
      category: current.category,
    );
    await _persistCache(cached);
  }

  Future<bool> toggleSavedMusic(MusicModel track) async {
    final uid = CurrentUserService.instance.effectiveUserId;
    final cleanId = track.docID.trim();
    if (uid.isEmpty || cleanId.isEmpty) return false;
    final existing = await _userSubcollectionRepository.getEntry(
      uid,
      subcollection: 'savedMusic',
      docId: cleanId,
      preferCache: true,
    );
    if (existing != null) {
      await _userSubcollectionRepository.deleteEntry(
        uid,
        subcollection: 'savedMusic',
        docId: cleanId,
      );
      return false;
    }
    await _userSubcollectionRepository.upsertEntry(
      uid,
      subcollection: 'savedMusic',
      docId: cleanId,
      data: {
        'musicId': cleanId,
        'title': track.title,
        'artist': track.artist,
        'audioUrl': track.audioUrl,
        'coverUrl': track.coverUrl,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      },
    );
    return true;
  }

  Future<void> recordStoryUsage({
    required MusicModel track,
    required String storyId,
    required String userId,
    required int createdAt,
  }) async {
    final cleanMusicId = track.docID.trim();
    final cleanStoryId = storyId.trim();
    final cleanUserId = userId.trim();
    if (cleanMusicId.isEmpty || cleanStoryId.isEmpty || cleanUserId.isEmpty) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await _collection.doc(cleanMusicId).set({
        'title': track.title,
        'artist': track.artist,
        'audioUrl': track.audioUrl,
        'coverUrl': track.coverUrl,
        'durationMs': track.durationMs,
        'category': track.category,
        'order': track.order,
        'isActive': true,
        'useCount': FieldValue.increment(1),
        'storyCount': FieldValue.increment(1),
        'shareCount': track.shareCount,
        'lastUsedAt': now,
        'createdAt': track.createdAt > 0 ? track.createdAt : now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      await _collection
          .doc(cleanMusicId)
          .collection('stories')
          .doc(cleanStoryId)
          .set({
        'storyId': cleanStoryId,
        'userId': cleanUserId,
        'createdAt': createdAt,
        'musicId': cleanMusicId,
      }, SetOptions(merge: true));
    } catch (_) {}

    await _updateCachedTrack(
      cleanMusicId,
      (current) => MusicModel(
        docID: current.docID,
        title: current.title,
        artist: current.artist,
        audioUrl: current.audioUrl,
        coverUrl: current.coverUrl,
        durationMs: current.durationMs,
        useCount: current.useCount + 1,
        shareCount: current.shareCount,
        storyCount: current.storyCount + 1,
        order: current.order,
        lastUsedAt: now,
        createdAt: current.createdAt,
        updatedAt: now,
        isActive: current.isActive,
        category: current.category,
      ),
    );
  }

  Future<void> removeStoryUsage({
    required String musicId,
    required String storyId,
  }) async {
    final cleanMusicId = musicId.trim();
    final cleanStoryId = storyId.trim();
    if (cleanMusicId.isEmpty || cleanStoryId.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await _collection
          .doc(cleanMusicId)
          .collection('stories')
          .doc(cleanStoryId)
          .delete();
      await _collection.doc(cleanMusicId).set({
        'storyCount': FieldValue.increment(-1),
        'updatedAt': now,
      }, SetOptions(merge: true));
    } catch (_) {}

    await _updateCachedTrack(
      cleanMusicId,
      (current) => MusicModel(
        docID: current.docID,
        title: current.title,
        artist: current.artist,
        audioUrl: current.audioUrl,
        coverUrl: current.coverUrl,
        durationMs: current.durationMs,
        useCount: current.useCount,
        shareCount: current.shareCount,
        storyCount: math.max(0, current.storyCount - 1),
        order: current.order,
        lastUsedAt: current.lastUsedAt,
        createdAt: current.createdAt,
        updatedAt: now,
        isActive: current.isActive,
        category: current.category,
      ),
    );
  }

  Future<void> restoreStoryUsage({
    required String musicId,
    required String storyId,
    required String userId,
    required int createdAt,
    required String title,
    required String artist,
    required String audioUrl,
    required String coverUrl,
  }) async {
    final cleanMusicId = musicId.trim();
    final cleanStoryId = storyId.trim();
    final cleanUserId = userId.trim();
    if (cleanMusicId.isEmpty || cleanStoryId.isEmpty || cleanUserId.isEmpty) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await _collection.doc(cleanMusicId).set({
        'title': title,
        'artist': artist,
        'audioUrl': audioUrl,
        'coverUrl': coverUrl,
        'storyCount': FieldValue.increment(1),
        'lastUsedAt': now,
        'updatedAt': now,
        'isActive': true,
      }, SetOptions(merge: true));
      await _collection
          .doc(cleanMusicId)
          .collection('stories')
          .doc(cleanStoryId)
          .set({
        'storyId': cleanStoryId,
        'userId': cleanUserId,
        'createdAt': createdAt,
        'musicId': cleanMusicId,
      }, SetOptions(merge: true));
    } catch (_) {}

    await _updateCachedTrack(
      cleanMusicId,
      (current) => MusicModel(
        docID: current.docID,
        title: title.isNotEmpty ? title : current.title,
        artist: artist.isNotEmpty ? artist : current.artist,
        audioUrl: audioUrl.isNotEmpty ? audioUrl : current.audioUrl,
        coverUrl: coverUrl.isNotEmpty ? coverUrl : current.coverUrl,
        durationMs: current.durationMs,
        useCount: current.useCount,
        shareCount: current.shareCount,
        storyCount: current.storyCount + 1,
        order: current.order,
        lastUsedAt: now,
        createdAt: current.createdAt,
        updatedAt: now,
        isActive: true,
        category: current.category,
      ),
    );
  }

  Future<String> resolvePlayablePath(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return '';

    try {
      final cached = await TurqImageCacheManager.instance.getFileFromCache(
        cleanUrl,
      );
      if (cached != null && await cached.file.exists()) {
        return cached.file.path;
      }
    } catch (_) {}

    try {
      final file = await TurqImageCacheManager.instance.getSingleFile(cleanUrl);
      return file.path;
    } catch (_) {
      return '';
    }
  }

  Future<void> warmTrack(MusicModel track) async {
    final cleanAudioUrl = track.audioUrl.trim();
    final cleanCoverUrl = track.coverUrl.trim();
    if (cleanAudioUrl.isNotEmpty) {
      try {
        await TurqImageCacheManager.instance.getSingleFile(cleanAudioUrl);
      } catch (_) {}
    }
    if (cleanCoverUrl.isNotEmpty) {
      try {
        await TurqImageCacheManager.instance.getSingleFile(cleanCoverUrl);
      } catch (_) {}
    }
  }

  Future<void> warmTrackFromStory({
    required String audioUrl,
    required String coverUrl,
  }) async {
    final cleanAudioUrl = audioUrl.trim();
    final cleanCoverUrl = coverUrl.trim();
    if (cleanAudioUrl.isNotEmpty) {
      try {
        await TurqImageCacheManager.instance.getSingleFile(cleanAudioUrl);
      } catch (_) {}
    }
    if (cleanCoverUrl.isNotEmpty) {
      try {
        await TurqImageCacheManager.instance.getSingleFile(cleanCoverUrl);
      } catch (_) {}
    }
  }

  Future<void> _updateCachedTrack(
    String musicId,
    MusicModel Function(MusicModel current) builder,
  ) async {
    final cached = await _loadCache(ignoreTtl: true);
    if (cached.isEmpty) return;
    final index = cached.indexWhere((e) => e.docID == musicId);
    if (index == -1) return;
    cached[index] = builder(cached[index]);
    await _persistCache(cached);
  }

  Future<void> _warmTopCache({required int limit}) async {
    final tracks = await _loadCache(ignoreTtl: true);
    if (tracks.isEmpty) return;
    final top = _sortAndLimit(tracks, limit);
    for (final track in top) {
      await warmTrack(track);
    }
  }
}
