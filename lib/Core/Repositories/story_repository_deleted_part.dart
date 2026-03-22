part of 'story_repository.dart';

extension StoryRepositoryDeletedPart on StoryRepository {
  Future<void> _performMarkExpiredStoriesDeleted(String uid) async {
    try {
      final expiry = DateTime.now().subtract(const Duration(hours: 24));
      final expiredSnap = await FirebaseFirestore.instance
          .collection('stories')
          .where('userId', isEqualTo: uid)
          .get();
      var didMutate = false;

      for (final doc in expiredSnap.docs) {
        try {
          final model = StoryModel.fromDoc(doc);
          if (model.createdAt.isAfter(expiry)) continue;
          await FirebaseFirestore.instance
              .collection('stories')
              .doc(model.id)
              .update({
            'deleted': true,
            'deletedAt': DateTime.now().millisecondsSinceEpoch,
            'deleteReason': 'expired',
          });
          didMutate = true;
        } catch (_) {}
      }
      if (didMutate) {
        await invalidateStoryCachesForUser(uid);
      }
    } catch (_) {}
  }

  Future<String> _performSoftDeleteStory(
    String storyId, {
    required String reason,
  }) async {
    if (storyId.isEmpty) return '';
    final raw = await getStoryRaw(storyId, preferCache: true) ?? const {};
    final musicId = (raw['musicId'] ?? '').toString().trim();
    final uid = (raw['userId'] ?? '').toString().trim();
    await FirebaseFirestore.instance.collection('stories').doc(storyId).update({
      'deleted': true,
      'deletedAt': DateTime.now().millisecondsSinceEpoch,
      'deleteReason': reason,
    });
    if (uid.isNotEmpty) {
      await invalidateStoryCachesForUser(uid);
    }
    return musicId;
  }

  Future<void> _performRestoreDeletedStory(String storyId) async {
    if (storyId.isEmpty) return;
    final raw = await getStoryRaw(storyId, preferCache: true) ?? const {};
    await FirebaseFirestore.instance.collection('stories').doc(storyId).update({
      'deleted': false,
      'deletedAt': 0,
      'deleteReason': FieldValue.delete(),
    });
    final uid = (raw['userId'] ?? '').toString().trim();
    if (uid.isNotEmpty) {
      await invalidateStoryCachesForUser(uid);
    }
  }

  Future<void> _performPermanentlyDeleteStory(String storyId) async {
    if (storyId.isEmpty) return;
    final raw = await getStoryRaw(storyId, preferCache: true) ?? const {};
    final uid = (raw['userId'] ?? '').toString().trim();
    final musicId = (raw['musicId'] ?? '').toString().trim();

    try {
      await FirebaseFirestore.instance
          .collection('stories')
          .doc(storyId)
          .delete();
    } catch (_) {}

    if (uid.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('DeletedStories')
            .doc(storyId)
            .delete();
      } catch (_) {}

      try {
        final archiveSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('DeletedStories')
            .where('storyId', isEqualTo: storyId)
            .get();
        for (final doc in archiveSnap.docs) {
          try {
            await doc.reference.delete();
          } catch (_) {}
        }
      } catch (_) {}
    }

    if (musicId.isNotEmpty) {
      unawaited(
        StoryMusicLibraryService.instance.removeStoryUsage(
          musicId: musicId,
          storyId: storyId,
        ),
      );
    }

    if (uid.isNotEmpty) {
      await invalidateStoryCachesForUser(uid);
    }
  }

  Future<String> _performRepostDeletedStory(StoryModel story) async {
    final uid = CurrentUserService.instance.effectiveUserId.isNotEmpty
        ? CurrentUserService.instance.effectiveUserId
        : story.userId;
    if (uid.trim().isEmpty) return '';

    final docRef = FirebaseFirestore.instance.collection('stories').doc();
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final storyId = docRef.id;

    final serialized = story.elements
        .map(
          (e) => <String, dynamic>{
            'type': e.type.toString().split('.').last,
            'content': e.content,
            'width': e.width,
            'height': e.height,
            'position': {'x': e.position.dx, 'y': e.position.dy},
            'rotation': e.rotation,
            'zIndex': e.zIndex,
            'isMuted': e.isMuted,
            'fontSize': e.fontSize,
            'aspectRatio': e.aspectRatio,
            'textColor': e.textColor,
            'textBgColor': e.textBgColor,
            'hasTextBg': e.hasTextBg,
            'textAlign': e.textAlign,
            'fontWeight': e.fontWeight,
            'italic': e.italic,
            'underline': e.underline,
            'shadowBlur': e.shadowBlur,
            'shadowOpacity': e.shadowOpacity,
            'fontFamily': e.fontFamily,
            'hasOutline': e.hasOutline,
            'outlineColor': e.outlineColor,
            'stickerType': e.stickerType,
            'stickerData': e.stickerData,
          },
        )
        .toList(growable: false);

    await docRef.set({
      'userId': uid,
      'createdDate': createdAt,
      'backgroundColor': story.backgroundColor.toARGB32(),
      'musicId': story.musicId,
      'musicUrl': story.musicUrl,
      'musicTitle': story.musicTitle,
      'musicArtist': story.musicArtist,
      'musicCoverUrl': story.musicCoverUrl,
      'elements': serialized,
      'deleted': false,
      'deletedAt': 0,
    });

    if (story.musicId.trim().isNotEmpty) {
      final track = await StoryMusicLibraryService.instance.fetchTrackById(
        story.musicId,
        preferCache: true,
      );
      if (track != null) {
        await StoryMusicLibraryService.instance.recordStoryUsage(
          track: track,
          storyId: storyId,
          userId: uid,
          createdAt: createdAt,
        );
      }
    }

    await invalidateStoryCachesForUser(uid);

    return storyId;
  }

  Future<DeletedStoryCachePayload?> _performRestoreDeletedStoriesCache(
    String uid,
  ) async {
    await _ensureInitialized();
    try {
      final raw = _prefs?.getString(_deletedStoriesCacheKey(uid));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final savedAtMs = (decoded['savedAt'] as num?)?.toInt() ?? 0;
      if (savedAtMs <= 0) return null;
      final cacheAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(savedAtMs),
      );
      if (cacheAge > deletedStoriesCacheTtlInternal) return null;
      final items = (decoded['items'] as List?) ?? const [];
      final restoredStories = <StoryModel>[];
      final restoredDeletedAt = <String, int>{};
      final restoredReasons = <String, String>{};
      for (final item in items) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item.cast<String, dynamic>());
        final storyMap = Map<String, dynamic>.from(
          (map['story'] as Map?)?.cast<String, dynamic>() ?? const {},
        );
        if (storyMap.isEmpty) continue;
        final story = StoryModel.fromCacheMap(storyMap);
        restoredStories.add(story);
        restoredDeletedAt[story.id] = (map['deletedAt'] as num?)?.toInt() ?? 0;
        final reason = (map['deleteReason'] ?? '').toString();
        if (reason.isNotEmpty) restoredReasons[story.id] = reason;
      }
      if (restoredStories.isEmpty) return null;
      return DeletedStoryCachePayload(
        stories: restoredStories,
        deletedAtById: restoredDeletedAt,
        deleteReasonById: restoredReasons,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _performPersistDeletedStoriesCache({
    required String uid,
    required List<StoryModel> stories,
    required Map<String, int> deletedAtById,
    required Map<String, String> deleteReasonById,
  }) async {
    await _ensureInitialized();
    try {
      final items = stories
          .map((story) => <String, dynamic>{
                'story': story.toCacheMap(),
                'deletedAt': deletedAtById[story.id] ?? 0,
                'deleteReason': deleteReasonById[story.id] ?? '',
              })
          .toList();
      await _prefs?.setString(
        _deletedStoriesCacheKey(uid),
        jsonEncode({
          'savedAt': DateTime.now().millisecondsSinceEpoch,
          'items': items,
        }),
      );
    } catch (_) {}
  }

  Future<void> _performClearDeletedStoriesCache(String uid) async {
    if (uid.isEmpty) return;
    await _ensureInitialized();
    try {
      await _prefs?.remove(_deletedStoriesCacheKey(uid));
    } catch (_) {}
  }

  Future<DeletedStoryCachePayload> _performFetchDeletedStories(
    String uid,
  ) async {
    final items = <StoryModel>[];
    final deletedAtById = <String, int>{};
    final deleteReasonById = <String, String>{};
    final seenStoryIds = <String>{};
    var deletedDocCount = 0;
    var parseErrorCount = 0;

    try {
      final archiveSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('DeletedStories')
          .get();

      for (final d in archiveSnap.docs) {
        try {
          final data = d.data();
          final storyId = (data['storyId'] ?? d.id).toString().trim();
          if (storyId.isEmpty || !seenStoryIds.add(storyId)) continue;
          deletedDocCount++;

          final createdAtMs = _asEpochMillis(
            data['createdAtOriginal'] ?? data['createdDate'],
            fallback: DateTime.now().millisecondsSinceEpoch,
          );

          final model = StoryModel.fromCacheMap(<String, dynamic>{
            'id': storyId,
            'userId': (data['userId'] ?? uid).toString(),
            'createdDate': createdAtMs,
            'backgroundColor':
                _asEpochMillis(data['backgroundColor'], fallback: 0xFF000000),
            'musicId': (data['musicId'] ?? '').toString(),
            'musicUrl': (data['musicUrl'] ?? '').toString(),
            'musicTitle': (data['musicTitle'] ?? '').toString(),
            'musicArtist': (data['musicArtist'] ?? '').toString(),
            'musicCoverUrl': (data['musicCoverUrl'] ?? '').toString(),
            'elements': _normalizeStoryElements(data['elements']),
          });
          items.add(model);
          deletedAtById[model.id] = _asEpochMillis(data['deletedAt']);
          final reason =
              (data['reason'] ?? data['deleteReason'] ?? '').toString().trim();
          if (reason.isNotEmpty) deleteReasonById[model.id] = reason;
        } catch (_) {
          parseErrorCount++;
          debugPrint('Deleted archive parse skipped');
        }
      }
    } catch (e) {
      debugPrint('Deleted stories archive fetch error: $e');
    }

    final snap = await FirebaseFirestore.instance
        .collection('stories')
        .where('userId', isEqualTo: uid)
        .get();

    for (final d in snap.docs) {
      try {
        final data = d.data();
        if ((data['deleted'] ?? false) != true) continue;
        if (!seenStoryIds.add(d.id)) continue;
        deletedDocCount++;
        final model = StoryModel.fromCacheMap(<String, dynamic>{
          'id': d.id,
          ...data,
          'createdDate': _asEpochMillis(
            data['createdDate'],
            fallback: DateTime.now().millisecondsSinceEpoch,
          ),
          'backgroundColor':
              _asEpochMillis(data['backgroundColor'], fallback: 0xFF000000),
          'elements': _normalizeStoryElements(data['elements']),
        });
        items.add(model);
        final delAt = _asEpochMillis(data['deletedAt']);
        deletedAtById[model.id] = delAt;
        final reason = (data['deleteReason'] ?? '').toString();
        if (reason.isNotEmpty) deleteReasonById[model.id] = reason;
      } catch (_) {
        parseErrorCount++;
        debugPrint('Deleted story parse skipped');
      }
    }

    debugPrint(
      'Deleted stories fetch: liveDocs=${snap.docs.length} '
      'deletedDocs=$deletedDocCount parsed=${items.length} parseErrors=$parseErrorCount '
      'reasons=${deleteReasonById.length}',
    );

    items.sort((a, b) {
      final aDeletedAt = deletedAtById[a.id] ?? 0;
      final bDeletedAt = deletedAtById[b.id] ?? 0;
      return bDeletedAt.compareTo(aDeletedAt);
    });

    final trimmed = items
        .take(deletedStoriesCacheLimitInternal)
        .toList(growable: false);
    final keptIds = trimmed.map((e) => e.id).toSet();
    deletedAtById.removeWhere((key, _) => !keptIds.contains(key));
    deleteReasonById.removeWhere((key, _) => !keptIds.contains(key));

    return DeletedStoryCachePayload(
      stories: trimmed,
      deletedAtById: deletedAtById,
      deleteReasonById: deleteReasonById,
    );
  }
}
