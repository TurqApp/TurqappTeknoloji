part of 'post_repository.dart';

extension PostRepositoryQueryPart on PostRepository {
  Future<Map<String, PostsModel>> _performFetchPostsByIds(
    List<String> postIds, {
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final cleaned = postIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cleaned.isEmpty) return const <String, PostsModel>{};

    final result = <String, PostsModel>{};
    final missing = <String>[];

    for (final id in cleaned) {
      final state = _states[id];
      final cached = preferCache ? state?.latestPostData.value : null;
      if (cached != null) {
        result[id] = PostsModel.fromMap(cached, id);
      } else {
        missing.add(id);
      }
    }

    for (int i = 0; i < missing.length; i += 10) {
      final chunk = missing.sublist(
        i,
        i + 10 > missing.length ? missing.length : i + 10,
      );
      final query = _firestore
          .collection('Posts')
          .where(FieldPath.documentId, whereIn: chunk);
      final snap = await _getQueryWithSource(
        query,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      for (final doc in snap.docs) {
        final data = doc.data();
        final model = _normalizeLikelyCompletedOwnPost(
          PostsModel.fromMap(data, doc.id),
        );
        result[doc.id] = model;
        final state =
            _states.putIfAbsent(doc.id, () => PostRepositoryState(doc.id));
        state.latestPostData.value = model.toMap();
        _seedCounts(state, model);
      }
    }

    return result;
  }

  Future<Map<String, PostsModel>> _performFetchPostCardsByIds(
    List<String> postIds, {
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final cleaned = postIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cleaned.isEmpty) return const <String, PostsModel>{};

    final result = <String, PostsModel>{};
    final missing = <String>[];

    for (final id in cleaned) {
      final state = _states[id];
      final cached = preferCache ? state?.latestPostData.value : null;
      if (cached != null) {
        result[id] = _normalizeLikelyCompletedOwnPost(
          PostsModel.fromMap(cached, id),
        );
      } else {
        missing.add(id);
      }
    }

    if (missing.isEmpty || cacheOnly) {
      return result;
    }

    Map<String, Map<String, dynamic>> typesenseDocs =
        <String, Map<String, dynamic>>{};
    try {
      typesenseDocs = await _typesensePostService.getPostCardsByIds(missing);
    } catch (_) {
      typesenseDocs = const <String, Map<String, dynamic>>{};
    }
    final fallbackIds = <String>[];
    final pollBackfillIds = <String>[];

    for (final id in missing) {
      final doc = typesenseDocs[id];
      if (doc == null) {
        fallbackIds.add(id);
        continue;
      }

      final raw = _typesenseDocToPostMap(doc, id);
      final model = _normalizeLikelyCompletedOwnPost(
        PostsModel.fromMap(raw, id),
      );
      result[id] = model;
      if (model.poll.isEmpty) {
        pollBackfillIds.add(id);
      }
      final state = _states.putIfAbsent(id, () => PostRepositoryState(id));
      state.latestPostData.value = model.toMap();
      _countManager.initializeCounts(
        model.docID,
        likeCount: model.stats.likeCount.toInt(),
        commentCount: model.stats.commentCount.toInt(),
        savedCount: model.stats.savedCount.toInt(),
        retryCount: model.stats.retryCount.toInt(),
        statsCount: model.stats.statsCount.toInt(),
      );
    }

    if (pollBackfillIds.isNotEmpty) {
      final firestorePollModels = await fetchPostsByIds(
        pollBackfillIds,
        preferCache: false,
        cacheOnly: false,
      );
      for (final entry in firestorePollModels.entries) {
        final firestoreModel = entry.value;
        if (firestoreModel.poll.isEmpty) continue;
        result[entry.key] = firestoreModel;
        final state =
            _states.putIfAbsent(entry.key, () => PostRepositoryState(entry.key));
        state.latestPostData.value = firestoreModel.toMap();
        _seedCounts(state, firestoreModel);
      }
    }

    if (fallbackIds.isNotEmpty) {
      final firestoreModels = await fetchPostsByIds(
        fallbackIds,
        preferCache: preferCache,
        cacheOnly: false,
      );
      for (final entry in firestoreModels.entries) {
        if (_isRenderableCard(entry.value)) {
          result[entry.key] = entry.value;
        }
      }
    }

    return result;
  }

  Future<PostQueryPage> _performFetchAgendaWindowPage({
    required int cutoffMs,
    required int nowMs,
    required int limit,
    required DocumentSnapshot? startAfter,
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .where('arsiv', isEqualTo: false)
        .where('flood', isEqualTo: false)
        .where('timeStamp', isGreaterThanOrEqualTo: cutoffMs)
        .orderBy('timeStamp', descending: true)
        .limit(limit * 3);
    if (startAfter != null) {
      query = query.startAfterDocument(
        startAfter as DocumentSnapshot<Map<String, dynamic>>,
      );
    }
    final snap = await _getQueryWithSource(
      query,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    final items = snap.docs
        .map((doc) => PostsModel.fromMap(doc.data(), doc.id))
        .where((post) => !post.shouldHideWhileUploading)
        .where((post) => _isRenderableCard(post))
        .take(limit)
        .toList(growable: false);
    return PostQueryPage(
      items: items,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  Future<UserFeedReferencePage> _performFetchUserFeedReferences({
    required String uid,
    required int limit,
    required DocumentSnapshot<Map<String, dynamic>>? startAfter,
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return const UserFeedReferencePage(
        items: <UserFeedReference>[],
        lastDoc: null,
      );
    }

    Query<Map<String, dynamic>> query = _firestore
        .collection('userFeeds')
        .doc(normalizedUid)
        .collection('items')
        .orderBy('timeStamp', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await _getQueryWithSource(
      query,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    final items = snap.docs
        .map((doc) {
          final data = doc.data();
          return UserFeedReference(
            postId: (data['postId'] ?? doc.id).toString().trim(),
            authorId: (data['authorId'] ?? '').toString().trim(),
            timeStamp: (data['timeStamp'] as num?)?.toInt() ?? 0,
            isCelebrity: data['isCelebrity'] == true,
            expiresAt: (data['expiresAt'] as num?)?.toInt() ?? 0,
          );
        })
        .where((item) => item.postId.isNotEmpty)
        .toList(growable: false);

    if (_shouldLogDiagnostics) {
      debugPrint(
        '[FeedRefs] uid=$normalizedUid count=${items.length} '
        'startAfter=${startAfter?.id ?? ''} '
        'sample=${items.take(5).map((item) => item.postId).join(',')}',
      );
    }

    return UserFeedReferencePage(
      items: items,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  Future<List<String>> _performFetchCelebrityAuthorIds(
    List<String> authorIds, {
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final cleaned = authorIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cleaned.isEmpty) return const <String>[];

    final celebIds = <String>{};
    for (int i = 0; i < cleaned.length; i += 10) {
      final chunk = cleaned.sublist(
        i,
        i + 10 > cleaned.length ? cleaned.length : i + 10,
      );
      final snap = await _getQueryWithSource(
        _firestore
            .collection('celebAccounts')
            .where(FieldPath.documentId, whereIn: chunk),
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      celebIds.addAll(snap.docs.map((doc) => doc.id));
    }
    return celebIds.toList(growable: false);
  }

  Future<List<PostsModel>> _performFetchRecentPostsForAuthors(
    List<String> authorIds, {
    required int nowMs,
    required int cutoffMs,
    required int perAuthorLimit,
    required int maxConcurrent,
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final cleaned = authorIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cleaned.isEmpty) return const <PostsModel>[];

    final nested = <List<PostsModel>>[];
    final concurrency = maxConcurrent < 1 ? 1 : maxConcurrent;
    for (int i = 0; i < cleaned.length; i += concurrency) {
      final chunk = cleaned.sublist(
        i,
        i + concurrency > cleaned.length ? cleaned.length : i + concurrency,
      );
      final futures = chunk.map((authorId) async {
        final snap = await _getQueryWithSource(
          _firestore
              .collection('Posts')
              .where('userID', isEqualTo: authorId)
              .where('arsiv', isEqualTo: false)
              .where('deletedPost', isEqualTo: false)
              .orderBy('timeStamp', descending: true)
              .limit(perAuthorLimit),
          preferCache: preferCache,
          cacheOnly: cacheOnly,
        );
        return snap.docs
            .map(
              (doc) => _normalizeLikelyCompletedOwnPost(
                PostsModel.fromMap(doc.data(), doc.id),
              ),
            )
            .where(
              (post) =>
                  !post.shouldHideWhileUploading &&
                  post.timeStamp >= cutoffMs &&
                  (post.timeStamp <= nowMs || post.scheduledAt.toInt() > 0),
            )
            .toList(growable: false);
      });
      nested.addAll(await Future.wait(futures));
    }

    final merged = <String, PostsModel>{};
    for (final posts in nested) {
      for (final post in posts) {
        merged.putIfAbsent(post.docID, () => post);
      }
    }
    final sorted = merged.values.toList()
      ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    return sorted;
  }

  Future<List<PostsModel>> _performFetchPublicScheduledIzBirakPosts({
    required int nowMs,
    required int cutoffMs,
    required int limit,
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final snap = await _getQueryWithSource(
      _firestore
          .collection('Posts')
          .where('arsiv', isEqualTo: false)
          .where('deletedPost', isEqualTo: false)
          .where('flood', isEqualTo: false)
          .where('timeStamp', isGreaterThanOrEqualTo: cutoffMs)
          .orderBy('timeStamp', descending: true)
          .limit(limit * 3),
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );

    final merged = <String, PostsModel>{};
    for (final doc in snap.docs) {
      final model = PostsModel.fromMap(doc.data(), doc.id);
      if (model.shouldHideWhileUploading) continue;
      final ts = model.timeStamp.toInt();
      final publishAt = model.izBirakYayinTarihi.toInt();
      final scheduledAt = model.scheduledAt.toInt();
      final effectivePublishAt = publishAt > 0 ? publishAt : scheduledAt;
      if (ts < cutoffMs) continue;
      if (effectivePublishAt <= 0) continue;
      if (effectivePublishAt <= nowMs) continue;
      merged[model.docID] = model;
      if (merged.length >= limit) break;
    }

    final sorted = merged.values.toList()
      ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    return sorted;
  }

  Future<List<PostsModel>> _performFetchRecentGlobalPosts({
    required int nowMs,
    required int cutoffMs,
    required int limit,
    required int? maxTimeExclusive,
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .where('arsiv', isEqualTo: false)
        .where('deletedPost', isEqualTo: false)
        .where('flood', isEqualTo: false)
        .where('timeStamp', isGreaterThanOrEqualTo: cutoffMs)
        .orderBy('timeStamp', descending: true)
        .limit(limit * 6);
    if (maxTimeExclusive != null && maxTimeExclusive > 0) {
      query = query.where('timeStamp', isLessThan: maxTimeExclusive);
    }

    final snap = await _getQueryWithSource(
      query,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );

    final merged = <String, PostsModel>{};
    for (final doc in snap.docs) {
      final model = PostsModel.fromMap(doc.data(), doc.id);
      if (model.shouldHideWhileUploading) continue;
      if (!_isRenderableCard(model)) continue;
      final ts = model.timeStamp.toInt();
      if (ts < cutoffMs || ts > nowMs) continue;
      merged[model.docID] = model;
      if (merged.length >= limit) break;
    }

    final sorted = merged.values.toList()
      ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    return sorted;
  }

  Future<PostsModel?> _performFetchPostById(
    String postId, {
    required bool preferCache,
  }) async {
    final normalized = postId.trim();
    if (normalized.isEmpty) return null;
    final items = await fetchPostsByIds(
      <String>[normalized],
      preferCache: preferCache,
    );
    return items[normalized];
  }

  void _performMergeCachedPostData(String postId, Map<String, dynamic> patch) {
    final normalized = postId.trim();
    if (normalized.isEmpty || patch.isEmpty) return;
    final state =
        _states.putIfAbsent(normalized, () => PostRepositoryState(normalized));
    final current = Map<String, dynamic>.from(state.latestPostData.value ?? {});
    current.addAll(patch);
    state.latestPostData.value = current;
  }

  Future<Map<String, dynamic>?> _performFetchPostRawById(
    String postId, {
    required bool preferCache,
  }) async {
    final normalized = postId.trim();
    if (normalized.isEmpty) return null;
    final state = _states[normalized];
    final cached = preferCache ? state?.latestPostData.value : null;
    if (cached != null) {
      return Map<String, dynamic>.from(cached);
    }

    final doc = await _firestore.collection('Posts').doc(normalized).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    final nextState =
        _states.putIfAbsent(normalized, () => PostRepositoryState(normalized));
    nextState.latestPostData.value = Map<String, dynamic>.from(data);
    return Map<String, dynamic>.from(data);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _performGetQueryWithSource(
    Query<Map<String, dynamic>> query, {
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    if (preferCache) {
      try {
        final cached = await query.get(const GetOptions(source: Source.cache));
        if (cacheOnly || cached.docs.isNotEmpty) {
          return cached;
        }
        return query.get(const GetOptions(source: Source.server));
      } catch (_) {
        if (cacheOnly) rethrow;
        return query.get(const GetOptions(source: Source.server));
      }
    }
    if (cacheOnly) {
      return query.get(const GetOptions(source: Source.cache));
    }
    return query.get(const GetOptions(source: Source.server));
  }

  Future<String?> _performResolveDocumentIdByLegacyId(
    String legacyId, {
    required bool preferCache,
  }) async {
    final normalized = legacyId.trim();
    if (normalized.isEmpty) return null;
    if (_states.containsKey(normalized)) {
      return normalized;
    }
    final byDocId = await fetchPostRawById(
      normalized,
      preferCache: preferCache,
    );
    if (byDocId != null) {
      return normalized;
    }
    final snap = await _firestore
        .collection('Posts')
        .where('id', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    final state =
        _states.putIfAbsent(doc.id, () => PostRepositoryState(doc.id));
    state.latestPostData.value = Map<String, dynamic>.from(doc.data());
    return doc.id;
  }

  bool _performIsRenderableCard(PostsModel model) {
    if (model.deletedPost || model.gizlendi || model.isUploading) {
      return false;
    }
    final hasVisual = model.thumbnail.trim().isNotEmpty || model.img.isNotEmpty;
    if (model.hasVideoSignal) {
      return model.hasRenderableVideoCard && hasVisual;
    }
    return model.metin.trim().isNotEmpty || hasVisual || model.floodCount > 1;
  }

  PostsModel _performNormalizeLikelyCompletedOwnPost(PostsModel model) {
    if (!_shouldRepairStuckUploading(model)) {
      return model;
    }
    model.isUploading = false;
    unawaited(_repairStuckUploadingPost(model));
    return model;
  }

  bool _performShouldRepairStuckUploading(PostsModel model) {
    if (!model.isUploading) return false;
    final currentUser = _auth.currentUser;
    final currentUid = currentUser == null ? '' : currentUser.uid.trim();
    if (currentUid.isEmpty || model.userID.trim() != currentUid) return false;
    if (model.deletedPost || model.arsiv || model.gizlendi) return false;
    final ageMs =
        DateTime.now().millisecondsSinceEpoch - model.timeStamp.toInt();
    if (ageMs < _postRepositoryStuckUploadingRepairAge.inMilliseconds) {
      return false;
    }
    final hasCompletedMedia = model.img.isNotEmpty ||
        model.thumbnail.trim().isNotEmpty ||
        model.hasHls ||
        model.video.trim().isNotEmpty;
    return hasCompletedMedia || model.metin.trim().isNotEmpty;
  }

  Future<void> _performRepairStuckUploadingPost(PostsModel model) async {
    final docId = model.docID.trim();
    if (docId.isEmpty) return;
    if (_postRepositoryUploadRepairInFlight.contains(docId)) return;
    _postRepositoryUploadRepairInFlight.add(docId);
    try {
      await _firestore.collection('Posts').doc(docId).set(<String, dynamic>{
        'isUploading': false,
      }, SetOptions(merge: true));
      final state =
          _states.putIfAbsent(docId, () => PostRepositoryState(docId));
      state.latestPostData.value = model.toMap()..['isUploading'] = false;
      if (kDebugMode) {
        debugPrint('[PostRepository] repairedStuckUploading postId=$docId');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[PostRepository] repairStuckUploadingFailed postId=$docId error=$error',
        );
      }
    } finally {
      _postRepositoryUploadRepairInFlight.remove(docId);
    }
  }

  Map<String, dynamic> _performTypesenseDocToPostMap(
    Map<String, dynamic> doc,
    String docId,
  ) {
    List<String> asStringList(dynamic value) {
      if (value is! List) return const <String>[];
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    num asNum(dynamic value, [num fallback = 0]) {
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? fallback;
      return fallback;
    }

    bool asBool(dynamic value) => value == true;

    Map<String, dynamic> asMap(dynamic value) {
      if (value is Map<String, dynamic>) {
        return Map<String, dynamic>.from(value);
      }
      if (value is Map) {
        return value.map(
          (key, val) => MapEntry(key.toString(), val),
        );
      }
      return const <String, dynamic>{};
    }

    final imageUrls = asStringList(doc['img']);
    final thumbnail = (doc['thumbnail'] ?? '').toString();
    final video = (doc['video'] ?? '').toString();
    final hlsMasterUrl = (doc['hlsMasterUrl'] ?? '').toString();
    final ctaLabel = (doc['ctaLabel'] ?? '').toString().trim();
    final ctaUrl = (doc['ctaUrl'] ?? '').toString().trim();
    final ctaType = (doc['ctaType'] ?? '').toString().trim();
    final ctaDocId = (doc['ctaDocId'] ?? '').toString().trim();
    final hasCta = ctaLabel.isNotEmpty ||
        ctaUrl.isNotEmpty ||
        ctaType.isNotEmpty ||
        ctaDocId.isNotEmpty;

    return <String, dynamic>{
      'metin': (doc['metin'] ?? '').toString(),
      'img': imageUrls,
      'thumbnail': thumbnail,
      'video': video,
      'hlsMasterUrl': hlsMasterUrl,
      'hlsStatus': (doc['hlsStatus'] ?? 'none').toString(),
      'hlsUpdatedAt': 0,
      'timeStamp': asNum(doc['timeStamp']),
      'editTime': asNum(doc['editTime']),
      'authorNickname': (doc['authorNickname'] ?? '').toString(),
      'authorDisplayName': (doc['authorDisplayName'] ?? '').toString(),
      'authorAvatarUrl': (doc['authorAvatarUrl'] ?? '').toString(),
      'rozet': (doc['rozet'] ?? '').toString(),
      'userID': (doc['userID'] ?? '').toString(),
      'paylasGizliligi': asNum(doc['paylasGizliligi'], 0),
      'arsiv': asBool(doc['arsiv']),
      'deletedPost': asBool(doc['deletedPost']),
      'gizlendi': asBool(doc['gizlendi']),
      'isUploading': asBool(doc['isUploading']),
      'aspectRatio': asNum(doc['aspectRatio'], 1.77),
      'flood': asBool(doc['flood']),
      'floodCount': asNum(doc['floodCount'], 1),
      'mainFlood': (doc['mainFlood'] ?? '').toString(),
      'locationCity': (doc['locationCity'] ?? '').toString(),
      'originalPostID': (doc['originalPostID'] ?? '').toString(),
      'originalUserID': (doc['originalUserID'] ?? '').toString(),
      'quotedPost': asBool(doc['quotedPost']),
      'tags': asStringList(doc['hashtags']),
      'yorum': true,
      'yorumMap': const <String, dynamic>{},
      'reshareMap': hasCta
          ? <String, dynamic>{
              'visibility': 0,
              if (ctaLabel.isNotEmpty) 'ctaLabel': ctaLabel,
              if (ctaUrl.isNotEmpty) 'ctaUrl': ctaUrl,
              if (ctaType.isNotEmpty) 'ctaType': ctaType,
              if (ctaDocId.isNotEmpty) 'ctaDocId': ctaDocId,
            }
          : const <String, dynamic>{},
      'poll': asMap(doc['poll']),
      'ad': false,
      'isAd': false,
      'debugMode': false,
      'deletedPostTime': 0,
      'izBirakYayinTarihi': 0,
      'konum': (doc['locationCity'] ?? '').toString(),
      'scheduledAt': 0,
      'sikayetEdildi': false,
      'stabilized': true,
      'videoLook': const <String, dynamic>{
        'preset': 'original',
        'version': 1,
        'intensity': 1.0,
      },
      'stats': <String, dynamic>{
        'likeCount': asNum(doc['likeCount']),
        'commentCount': asNum(doc['commentCount']),
        'savedCount': asNum(doc['savedCount']),
        'retryCount': asNum(doc['retryCount']),
        'statsCount': asNum(doc['statsCount']),
        'reportedCount': 0,
      },
      'docID': docId,
    };
  }
}
