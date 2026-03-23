part of 'notify_lookup_repository.dart';

extension NotifyLookupRepositoryQueryPart on NotifyLookupRepository {
  Future<NotifyPostLookup> getPostLookup(String postID) async {
    _pruneStaleLookups();
    final cached = _postLookupCache[postID];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            NotifyLookupRepository._postLookupTtl) {
      return cached;
    }

    final doc = await _firestore.collection('Posts').doc(postID).get();
    final lookup = NotifyPostLookup(
      exists: doc.exists,
      model: doc.exists ? PostsModel.fromFirestore(doc) : null,
      cachedAt: DateTime.now(),
    );
    _postLookupCache[postID] = lookup;
    return lookup;
  }

  Future<NotifyChatLookup> getChatLookup(String chatID) async {
    _pruneStaleLookups();
    final currentUid = CurrentUserService.instance.effectiveUserId;
    final cacheKey = '${currentUid}_$chatID';
    final cached = _chatLookupCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            NotifyLookupRepository._chatLookupTtl) {
      return cached;
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
    return lookup;
  }

  Future<NotifyJobLookup> getJobLookup(String jobID) async {
    _pruneStaleLookups();
    final cached = _jobLookupCache[jobID];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            NotifyLookupRepository._jobLookupTtl) {
      return cached;
    }
    final doc = await _firestore.collection('isBul').doc(jobID).get();
    final lookup = NotifyJobLookup(
      exists: doc.exists,
      model: doc.exists ? JobModel.fromMap(doc.data()!, doc.id) : null,
      cachedAt: DateTime.now(),
    );
    _jobLookupCache[jobID] = lookup;
    return lookup;
  }

  Future<NotifyTutoringLookup> getTutoringLookup(String tutoringID) async {
    _pruneStaleLookups();
    final cached = _tutoringLookupCache[tutoringID];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            NotifyLookupRepository._tutoringLookupTtl) {
      return cached;
    }
    final doc = await _firestore.collection('educators').doc(tutoringID).get();
    final lookup = NotifyTutoringLookup(
      exists: doc.exists,
      model: doc.exists ? TutoringModel.fromJson(doc.data()!, doc.id) : null,
      cachedAt: DateTime.now(),
    );
    _tutoringLookupCache[tutoringID] = lookup;
    return lookup;
  }

  Future<NotifyMarketLookup> getMarketLookup(String itemId) async {
    _pruneStaleLookups();
    final cached = _marketLookupCache[itemId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            NotifyLookupRepository._marketLookupTtl) {
      return cached;
    }
    final model = await MarketRepository.ensure().fetchById(
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
    return lookup;
  }
}
