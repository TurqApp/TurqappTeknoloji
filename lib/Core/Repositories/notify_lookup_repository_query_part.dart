part of 'notify_lookup_repository_library.dart';

extension NotifyLookupRepositoryQueryPart on NotifyLookupRepository {
  Future<NotifyPostLookup> getPostLookup(String postID) async {
    _pruneStaleLookups();
    final cached = _postLookupCache[postID];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _notifyPostLookupTtl) {
      return _clonePostLookup(cached);
    }

    final doc = await _firestore.collection('Posts').doc(postID).get();
    final lookup = NotifyPostLookup(
      exists: doc.exists,
      model: doc.exists ? PostsModel.fromFirestore(doc) : null,
      cachedAt: DateTime.now(),
    );
    _postLookupCache[postID] = lookup;
    return _clonePostLookup(lookup);
  }

  Future<NotifyChatLookup> getChatLookup(String chatID) async {
    _pruneStaleLookups();
    final currentUid = CurrentUserService.instance.effectiveUserId;
    final cacheKey = '${currentUid}_$chatID';
    final cached = _chatLookupCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _notifyChatLookupTtl) {
      return _cloneChatLookup(cached);
    }
    if (currentUid.isEmpty) {
      return NotifyChatLookup(otherUser: '', cachedAt: DateTime.now());
    }

    var otherUser = '';
    try {
      final convDoc =
          await _firestore.collection('conversations').doc(chatID).get();
      if (convDoc.exists) {
        final participants =
            List<String>.from(convDoc.data()?['participants'] ?? const []);
        otherUser = participants.firstWhere(
          (id) => id != currentUid,
          orElse: () => '',
        );
      }
    } catch (_) {}

    if (otherUser.isEmpty) {
      for (final part in chatID.split('_')) {
        final candidate = part.trim();
        if (candidate.isNotEmpty && candidate != currentUid) {
          otherUser = candidate;
          break;
        }
      }
    }

    final lookup = NotifyChatLookup(
      otherUser: otherUser,
      cachedAt: DateTime.now(),
    );
    _chatLookupCache[cacheKey] = lookup;
    return _cloneChatLookup(lookup);
  }

  Future<NotifyJobLookup> getJobLookup(String jobID) async {
    _pruneStaleLookups();
    final cached = _jobLookupCache[jobID];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _notifyJobLookupTtl) {
      return _cloneJobLookup(cached);
    }
    final doc = await _firestore.collection('isBul').doc(jobID).get();
    final lookup = NotifyJobLookup(
      exists: doc.exists,
      model: doc.exists ? JobModel.fromMap(doc.data()!, doc.id) : null,
      cachedAt: DateTime.now(),
    );
    _jobLookupCache[jobID] = lookup;
    return _cloneJobLookup(lookup);
  }

  Future<NotifyTutoringLookup> getTutoringLookup(String tutoringID) async {
    _pruneStaleLookups();
    final cached = _tutoringLookupCache[tutoringID];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            _notifyTutoringLookupTtl) {
      return _cloneTutoringLookup(cached);
    }
    final doc = await _firestore.collection('educators').doc(tutoringID).get();
    final lookup = NotifyTutoringLookup(
      exists: doc.exists,
      model: doc.exists ? TutoringModel.fromJson(doc.data()!, doc.id) : null,
      cachedAt: DateTime.now(),
    );
    _tutoringLookupCache[tutoringID] = lookup;
    return _cloneTutoringLookup(lookup);
  }

  Future<NotifyMarketLookup> getMarketLookup(String itemId) async {
    _pruneStaleLookups();
    final cached = _marketLookupCache[itemId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _notifyMarketLookupTtl) {
      return _cloneMarketLookup(cached);
    }
    final model = await ensureMarketRepository().fetchById(
      itemId,
      preferCache: true,
      forceRefresh: false,
    );
    final lookup = NotifyMarketLookup(
      exists: model != null,
      model: model,
      cachedAt: DateTime.now(),
    );
    _marketLookupCache[itemId] = lookup;
    return _cloneMarketLookup(lookup);
  }

  NotifyPostLookup _clonePostLookup(NotifyPostLookup lookup) {
    return NotifyPostLookup(
      exists: lookup.exists,
      model: lookup.model == null
          ? null
          : PostsModel.fromMap(lookup.model!.toMap(), lookup.model!.docID),
      cachedAt: lookup.cachedAt,
    );
  }

  NotifyChatLookup _cloneChatLookup(NotifyChatLookup lookup) {
    return NotifyChatLookup(
      otherUser: lookup.otherUser,
      cachedAt: lookup.cachedAt,
    );
  }

  NotifyJobLookup _cloneJobLookup(NotifyJobLookup lookup) {
    final model = lookup.model;
    return NotifyJobLookup(
      exists: lookup.exists,
      model: model == null
          ? null
          : JobModel.fromMap(model.toMap(), model.docID),
      cachedAt: lookup.cachedAt,
    );
  }

  NotifyTutoringLookup _cloneTutoringLookup(NotifyTutoringLookup lookup) {
    final model = lookup.model;
    return NotifyTutoringLookup(
      exists: lookup.exists,
      model: model == null
          ? null
          : TutoringModel.fromJson(model.toJson(), model.docID),
      cachedAt: lookup.cachedAt,
    );
  }

  NotifyMarketLookup _cloneMarketLookup(NotifyMarketLookup lookup) {
    final model = lookup.model;
    return NotifyMarketLookup(
      exists: lookup.exists,
      model: model == null
          ? null
          : MarketItemModel.fromJson(model.toJson()),
      cachedAt: lookup.cachedAt,
    );
  }
}
