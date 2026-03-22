part of 'post_repository.dart';

extension PostRepositorySharingPart on PostRepository {
  Future<List<PostReshareEntry>> fetchAllReshareEntries(
    String postId, {
    int limit = 200,
  }) async {
    if (postId.trim().isEmpty) return const <PostReshareEntry>[];
    final snap = await _firestore
        .collection('Posts')
        .doc(postId.trim())
        .collection('reshares')
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((doc) => PostReshareEntry(
              userId: (doc.data()['userID'] ?? doc.id).toString().trim(),
              timeStamp: ((doc.data()['timeStamp'] ?? 0) as num).toInt(),
              quotedPost: doc.data()['quotedPost'] == true,
            ))
        .where((entry) => entry.userId.isNotEmpty)
        .toList(growable: false);
  }

  Future<Map<String, int>> fetchUserResharedPosts(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
    int limit = 200,
  }) async {
    if (uid.trim().isEmpty) return const <String, int>{};
    final entries = await _userSubcollectionRepository.getEntries(
      uid.trim(),
      subcollection: 'reshared_posts',
      orderByField: 'timeStamp',
      descending: true,
      preferCache: preferCache,
      forceRefresh: forceRefresh,
    );
    final map = <String, int>{};
    for (final entry in entries.take(limit)) {
      final data = entry.data;
      final postId = (data['post_docID'] ?? entry.id).toString().trim();
      if (postId.isEmpty) continue;
      final ts = (data['timeStamp'] as num?)?.toInt() ??
          int.tryParse('${data['timeStamp']}') ??
          0;
      map[postId] = ts;
    }
    return map;
  }

  Future<List<Map<String, dynamic>>> fetchCollectionGroupReshares({
    int limit = 500,
  }) async {
    final snap =
        await _firestore.collectionGroup('reshares').limit(limit).get();
    return snap.docs
        .map((doc) {
          final postRef = doc.reference.parent.parent;
          final postId = postRef?.id ?? '';
          final data = doc.data();
          return <String, dynamic>{
            'postID': postId,
            'userID': doc.id,
            'timeStamp': ((data['timeStamp'] ?? 0) as num).toInt(),
            'originalUserID': (data['originalUserID'] ?? '').toString(),
            'originalPostID': (data['originalPostID'] ?? '').toString(),
            'quotedPost': data['quotedPost'] == true,
            'type': 'reshare',
          };
        })
        .where((entry) =>
            (entry['postID'] as String).isNotEmpty &&
            entry['quotedPost'] != true)
        .toList(growable: false);
  }

  Future<void> restoreDeletedPostsForUser(String uid) async {
    if (uid.trim().isEmpty) return;
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .where('userID', isEqualTo: uid.trim())
        .where('deletedPost', isEqualTo: true)
        .limit(400);

    while (true) {
      final snap = await query.get();
      if (snap.docs.isEmpty) break;

      final batch = _firestore.batch();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final doc in snap.docs) {
        batch.update(doc.reference, {
          'deletedPost': false,
          'deletedPostTime': 0,
          'updatedDate': now,
        });
        final state =
            _states.putIfAbsent(doc.id, () => PostRepositoryState(doc.id));
        final cached = Map<String, dynamic>.from(
          state.latestPostData.value ?? doc.data(),
        )
          ..['deletedPost'] = false
          ..['deletedPostTime'] = 0
          ..['updatedDate'] = now;
        state.latestPostData.value = cached;
      }
      await batch.commit();

      if (snap.docs.length < 400) break;
      query = _firestore
          .collection('Posts')
          .where('userID', isEqualTo: uid.trim())
          .where('deletedPost', isEqualTo: true)
          .startAfterDocument(snap.docs.last)
          .limit(400);
    }
  }

  Future<void> markAllPostsDeletedForUser(
    String uid, {
    int? nowMs,
  }) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return;
    final timestamp = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .where('userID', isEqualTo: normalizedUid)
        .limit(200);

    while (true) {
      final snap = await query.get();
      if (snap.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {
          'isDeleted': true,
          'deletedPost': true,
          'deletedPostTime': timestamp,
          'updatedDate': timestamp,
        });
        final state =
            _states.putIfAbsent(doc.id, () => PostRepositoryState(doc.id));
        final cached = Map<String, dynamic>.from(
          state.latestPostData.value ?? doc.data(),
        )
          ..['isDeleted'] = true
          ..['deletedPost'] = true
          ..['deletedPostTime'] = timestamp
          ..['updatedDate'] = timestamp;
        state.latestPostData.value = cached;
      }
      await batch.commit();

      if (snap.docs.length < 200) break;
      query = _firestore
          .collection('Posts')
          .where('userID', isEqualTo: normalizedUid)
          .startAfterDocument(snap.docs.last)
          .limit(200);
    }
  }

  Future<List<PostSharersModel>> fetchPostSharers(
    String postId, {
    bool preferCache = true,
  }) async {
    if (postId.trim().isEmpty) return const <PostSharersModel>[];
    final normalizedPostId = postId.trim();
    final cached = _postSharersMemory[normalizedPostId];
    if (preferCache && cached != null) {
      return List<PostSharersModel>.from(cached);
    }

    final snapshot = await _firestore
        .collection('Posts')
        .doc(normalizedPostId)
        .collection('postSharers')
        .orderBy('timestamp', descending: true)
        .get(const GetOptions(source: Source.serverAndCache));

    final sharers = snapshot.docs
        .map((doc) => PostSharersModel.fromMap(doc.data()))
        .toList(growable: false);
    _postSharersMemory[normalizedPostId] = List<PostSharersModel>.from(sharers);
    return sharers;
  }

  Future<PostSharersPage> fetchPostSharersPage(
    String postId, {
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    int limit = 20,
  }) async {
    final normalizedPostId = postId.trim();
    if (normalizedPostId.isEmpty) {
      return const PostSharersPage(
        items: <PostSharersModel>[],
        lastDoc: null,
        hasMore: false,
      );
    }

    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .doc(normalizedPostId)
        .collection('postSharers')
        .orderBy('timestamp', descending: true)
        .limit(limit);
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snap = await query.get();
    final items = snap.docs
        .map((doc) => PostSharersModel.fromMap(doc.data()))
        .toList(growable: false);
    return PostSharersPage(
      items: items,
      lastDoc: snap.docs.isEmpty ? lastDoc : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Future<List<PostSharersModel>> fetchSharedAsPostSharersFallback(
    String originalPostId,
  ) async {
    final normalizedPostId = originalPostId.trim();
    if (normalizedPostId.isEmpty) return const <PostSharersModel>[];

    final snap = await _firestore
        .collection('Posts')
        .where('originalPostID', isEqualTo: normalizedPostId)
        .where('sharedAsPost', isEqualTo: true)
        .get();

    final seenUserIds = <String>{};
    final items = snap.docs
        .map((doc) {
          final data = doc.data();
          final userId = (data['userID'] ?? '').toString().trim();
          final timestamp = (data['timeStamp'] as num?)?.toInt() ??
              int.tryParse('${data['timeStamp']}') ??
              0;
          if (userId.isEmpty) return null;
          if (data['deletedPost'] == true || data['quotedPost'] == true) {
            return null;
          }
          return PostSharersModel(
            userID: userId,
            timestamp: timestamp,
            sharedPostID: doc.id,
          );
        })
        .whereType<PostSharersModel>()
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return items.where((item) => seenUserIds.add(item.userID)).toList();
  }

  Future<PostSubcollectionPage> fetchLikeUserIdsPage(
    String postId, {
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    int limit = 20,
  }) async {
    if (postId.trim().isEmpty) {
      return const PostSubcollectionPage(
        userIds: <String>[],
        lastDoc: null,
        hasMore: false,
      );
    }
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .doc(postId.trim())
        .collection('likes')
        .orderBy('timeStamp', descending: true)
        .limit(limit);
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }
    final snap = await query.get();
    return PostSubcollectionPage(
      userIds: snap.docs.map((doc) => doc.id).toList(growable: false),
      lastDoc: snap.docs.isEmpty ? lastDoc : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Future<PostSubcollectionPage> fetchReshareUserIdsPage(
    String postId, {
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    int limit = 20,
  }) async {
    if (postId.trim().isEmpty) {
      return const PostSubcollectionPage(
        userIds: <String>[],
        lastDoc: null,
        hasMore: false,
      );
    }
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .doc(postId.trim())
        .collection('reshares')
        .orderBy('timeStamp', descending: true)
        .limit(limit);
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }
    final snap = await query.get();
    final filteredDocs = snap.docs
        .where((doc) => doc.data()['quotedPost'] != true)
        .toList(growable: false);
    return PostSubcollectionPage(
      userIds: filteredDocs
          .map((doc) => (doc.data()['userID'] ?? doc.id).toString())
          .where((id) => id.trim().isNotEmpty)
          .toList(growable: false),
      lastDoc: snap.docs.isEmpty ? lastDoc : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Future<PostSubcollectionPage> fetchQuoteUserIdsPage(
    String postId, {
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    int limit = 20,
  }) async {
    final normalizedPostId = postId.trim();
    if (normalizedPostId.isEmpty) {
      return const PostSubcollectionPage(
        userIds: <String>[],
        lastDoc: null,
        hasMore: false,
      );
    }

    Query<Map<String, dynamic>> quoteQuery = _firestore
        .collection('Posts')
        .doc(normalizedPostId)
        .collection('reshares')
        .orderBy('timeStamp', descending: true)
        .limit(limit * 3);
    if (lastDoc != null) {
      quoteQuery = quoteQuery.startAfterDocument(lastDoc);
    }

    final explicitSnap = await quoteQuery.get();
    final quoteDocs = explicitSnap.docs
        .where((doc) => doc.data()['quotedPost'] == true)
        .toList(growable: false);
    if (quoteDocs.isNotEmpty) {
      return PostSubcollectionPage(
        userIds: quoteDocs
            .map((doc) => (doc.data()['userID'] ?? doc.id).toString().trim())
            .where((id) => id.isNotEmpty)
            .toList(growable: false),
        lastDoc: explicitSnap.docs.last,
        hasMore: explicitSnap.docs.length >= (limit * 3),
      );
    }

    if (lastDoc != null) {
      return const PostSubcollectionPage(
        userIds: <String>[],
        lastDoc: null,
        hasMore: false,
      );
    }

    final collected = <String>[];
    final seen = <String>{};
    DocumentSnapshot<Map<String, dynamic>>? cursor;
    var hasMore = true;

    Future<void> collectQuotePostsByField(String field) async {
      final snap = await _firestore
          .collection('Posts')
          .where(field, isEqualTo: normalizedPostId)
          .where('quotedPost', isEqualTo: true)
          .limit(limit * 2)
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['deletedPost'] == true) continue;
        final userId = (data['userID'] ?? '').toString().trim();
        if (userId.isEmpty || seen.contains(userId)) continue;
        seen.add(userId);
        collected.add(userId);
        if (collected.length >= limit) return;
      }
    }

    await collectQuotePostsByField('sourcePostID');
    if (collected.length < limit) {
      await collectQuotePostsByField('originalPostID');
    }

    while (collected.length < limit && hasMore) {
      Query<Map<String, dynamic>> query = _firestore
          .collection('Posts')
          .doc(normalizedPostId)
          .collection('postSharers')
          .orderBy('timestamp', descending: true)
          .limit(limit);
      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final snap = await query.get();
      if (snap.docs.isEmpty) {
        hasMore = false;
        break;
      }

      cursor = snap.docs.last;
      if (snap.docs.length < limit) {
        hasMore = false;
      }

      final deferredSharedPostIds = <String>[];
      final deferredUserByPost = <String, String>{};

      for (final doc in snap.docs) {
        final data = doc.data();
        final userId = (data['userID'] ?? doc.id).toString().trim();
        if (userId.isEmpty || seen.contains(userId)) continue;

        final isQuoted = data['quotedPost'] == true;
        if (isQuoted) {
          seen.add(userId);
          collected.add(userId);
          if (collected.length >= limit) break;
          continue;
        }

        final sharedPostId = (data['sharedPostID'] ?? '').toString().trim();
        if (sharedPostId.isEmpty) continue;
        deferredSharedPostIds.add(sharedPostId);
        deferredUserByPost[sharedPostId] = userId;
      }

      if (collected.length >= limit || deferredSharedPostIds.isEmpty) {
        continue;
      }

      final sharedPosts = await fetchPostCardsByIds(
        deferredSharedPostIds,
        preferCache: true,
      );
      for (final entry in deferredUserByPost.entries) {
        final userId = entry.value;
        if (seen.contains(userId)) continue;
        final sharedPost = sharedPosts[entry.key];
        if (sharedPost == null) continue;
        if (sharedPost.quotedPost != true || sharedPost.deletedPost == true) {
          continue;
        }
        seen.add(userId);
        collected.add(userId);
        if (collected.length >= limit) break;
      }
    }

    return PostSubcollectionPage(
      userIds: collected,
      lastDoc: cursor,
      hasMore: hasMore,
    );
  }

  Future<List<String>> fetchDislikeUserIds(String postId) async {
    final normalized = postId.trim();
    if (normalized.isEmpty) return const <String>[];
    final snap = await _firestore
        .collection('Posts')
        .doc(normalized)
        .collection('Begenmemeler')
        .get();
    return snap.docs.map((doc) => doc.id).toList(growable: false);
  }

  Future<bool> ensureViewerSeen(
    String postId,
    String userId,
  ) async {
    final normalizedPostId = postId.trim();
    final normalizedUserId = userId.trim();
    if (normalizedPostId.isEmpty || normalizedUserId.isEmpty) return false;

    final viewersRef = _firestore
        .collection('Posts')
        .doc(normalizedPostId)
        .collection('viewers');
    final existing = await viewersRef
        .where('userID', isEqualTo: normalizedUserId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return false;
    }
    await viewersRef.doc().set({
      'userID': normalizedUserId,
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
    });
    await _countManager.updateStatsCount(normalizedPostId, by: 1);
    return true;
  }

  Future<String?> fetchLegacyResharedPostId(
    String postId,
    String userId,
  ) async {
    final normalizedPostId = postId.trim();
    final normalizedUserId = userId.trim();
    if (normalizedPostId.isEmpty || normalizedUserId.isEmpty) return null;
    final doc = await _firestore
        .collection('Posts')
        .doc(normalizedPostId)
        .collection('YenidenPaylas')
        .doc(normalizedUserId)
        .get();
    if (!doc.exists) return null;
    final resharedPostId = (doc.data()?['yeniPostID'] ?? '').toString().trim();
    return resharedPostId.isEmpty ? null : resharedPostId;
  }
}
