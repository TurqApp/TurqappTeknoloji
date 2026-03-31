part of 'post_interaction_service.dart';

extension PostInteractionServiceModerationPart on PostInteractionService {
  Future<bool> reportPost(String postId) async {
    if (!_isValidDocId(postId)) return false;
    if (!UserModerationGuard.ensureAllowed(RestrictedAction.comment)) {
      return false;
    }
    final userId = currentUserID;
    if (userId == null) return false;

    final postRef = _postRef(postId);
    final reporterDocRef = postRef.collection('reporters').doc(userId);
    bool reported = false;

    await _firestore.runTransaction((tx) async {
      final existing = await tx.get(reporterDocRef);
      if (existing.exists) return;

      final postSnap = await tx.get(postRef);
      final stats = _statsFromSnapshot(postSnap);

      tx.set(reporterDocRef,
          PostReporterModel(userID: userId, timeStamp: _nowMs()).toMap());
      tx.update(postRef, {'stats.reportedCount': stats.reportedCount + 1});
      reported = true;
    });

    if (reported) {
      _reportedByMe.add(postId);
      _updateInteractionCache(postId, reported: true);
    }

    return reported;
  }

  Future<ModerationFlagResult> flagPostWithReason(
    String postId, {
    required String reason,
  }) async {
    final userId = currentUserID;
    if (userId == null) {
      return const ModerationFlagResult(
        status: ModerationFlagStatus.unauthorized,
      );
    }

    final config = await _loadModerationConfig();
    if (!config.enabled) {
      return ModerationFlagResult(
        status: ModerationFlagStatus.disabled,
        threshold: config.threshold,
      );
    }

    final postRef = _postRef(postId);
    final normalizedReason = normalizeModerationReason(reason);

    bool alreadyFlagged = false;
    bool accepted = false;
    bool shadowHidden = false;
    int nextFlagCount = 0;
    final nowMs = _nowMs();

    await _firestore.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) return;

      final postData = postSnap.data() ?? const <String, dynamic>{};
      final moderationRaw = postData['moderation'];
      final moderation = moderationRaw is Map<String, dynamic>
          ? Map<String, dynamic>.from(moderationRaw)
          : (moderationRaw is Map
              ? Map<String, dynamic>.from(moderationRaw)
              : <String, dynamic>{});

      final flaggedByRaw = moderation['flaggedBy'];
      final flaggedBy = flaggedByRaw is List
          ? flaggedByRaw.map((e) => e.toString()).toList()
          : <String>[];

      nextFlagCount = _asInt(moderation['flagCount']);
      final currentStatus = (moderation['status'] ?? 'active').toString();

      if (config.allowSingleFlagPerUser && flaggedBy.contains(userId)) {
        alreadyFlagged = true;
        return;
      }

      nextFlagCount += 1;
      shadowHidden = config.enableShadowHide &&
          nextFlagCount >= config.threshold &&
          currentStatus != 'removed';

      final updates = <String, dynamic>{
        'moderation.flagCount': nextFlagCount,
        'moderation.flaggedBy': FieldValue.arrayUnion([userId]),
        'moderation.reasonsSummary.$normalizedReason': FieldValue.increment(1),
        'moderation.lastFlagAt': nowMs,
        'moderation.ownerNotified': moderation['ownerNotified'] ?? false,
      };

      if ((moderation['status'] ?? '').toString().trim().isEmpty) {
        updates['moderation.status'] = 'active';
      }

      if (shadowHidden) {
        updates['moderation.status'] = 'shadow_hidden';
        updates['moderation.thresholdReachedAt'] = nowMs;
        updates['moderation.shadowHiddenAt'] = nowMs;
      }

      tx.update(postRef, updates);
      accepted = true;
    });

    if (alreadyFlagged) {
      return ModerationFlagResult(
        status: ModerationFlagStatus.alreadyFlagged,
        flagCount: nextFlagCount,
        threshold: config.threshold,
        shadowHidden: shadowHidden,
      );
    }

    if (!accepted) {
      return ModerationFlagResult(
        status: ModerationFlagStatus.postNotFound,
        threshold: config.threshold,
      );
    }

    _reportedByMe.add(postId);
    _updateInteractionCache(postId, reported: true);
    return ModerationFlagResult(
      status: ModerationFlagStatus.accepted,
      flagCount: nextFlagCount,
      threshold: config.threshold,
      shadowHidden: shadowHidden,
    );
  }
}
