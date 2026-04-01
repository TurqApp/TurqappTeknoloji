part of 'story_highlights_repository.dart';

extension StoryHighlightsRepositoryActionPart on StoryHighlightsRepository {
  Future<void> setHighlights(
    String uid,
    List<StoryHighlightModel> items,
  ) async {
    if (uid.isEmpty) return;
    final cloned = items.map(_clone).toList(growable: false);
    final cachedAt = DateTime.now();
    _memory[uid] = _CachedStoryHighlights(items: cloned, cachedAt: cachedAt);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _prefsKey(uid),
      jsonEncode({
        't': cachedAt.millisecondsSinceEpoch,
        'items': cloned
            .map(
              (e) => {
                'id': e.id,
                'userId': e.userId,
                'title': e.title,
                'coverUrl': e.coverUrl,
                'storyIds': e.storyIds,
                'createdDate': e.createdAt.millisecondsSinceEpoch,
                'order': e.order,
              },
            )
            .toList(growable: false),
      }),
    );
  }

  Future<void> createHighlight(
    String uid,
    StoryHighlightModel model,
  ) async {
    if (uid.isEmpty || model.id.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('highlights')
        .doc(model.id)
        .set(model.toMap());
  }

  Future<void> addStoryToHighlight(
    String uid, {
    required String highlightId,
    required String storyId,
  }) async {
    if (uid.isEmpty || highlightId.isEmpty || storyId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('highlights')
        .doc(highlightId)
        .update({
      'storyIds': FieldValue.arrayUnion([storyId]),
    });
  }

  Future<void> updateHighlight(
    String uid, {
    required String highlightId,
    required String title,
    required String coverUrl,
  }) async {
    if (uid.isEmpty || highlightId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('highlights')
        .doc(highlightId)
        .update({
      'title': title,
      'coverUrl': coverUrl,
    });
  }

  Future<void> updateCoverUrl(
    String uid, {
    required String highlightId,
    required String coverUrl,
  }) async {
    if (uid.isEmpty || highlightId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('highlights')
        .doc(highlightId)
        .update({'coverUrl': coverUrl});
  }

  Future<void> deleteHighlight(
    String uid, {
    required String highlightId,
  }) async {
    if (uid.isEmpty || highlightId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('highlights')
        .doc(highlightId)
        .delete();
  }

  Future<void> invalidate(String uid) async {
    _memory.remove(uid);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_prefsKey(uid));
  }
}
