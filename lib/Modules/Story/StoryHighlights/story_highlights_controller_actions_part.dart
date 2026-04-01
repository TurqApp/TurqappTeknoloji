part of 'story_highlights_controller_library.dart';

extension _StoryHighlightsControllerActionsX on StoryHighlightsController {
  Future<StoryHighlightModel?> createHighlight({
    required String title,
    required List<String> storyIds,
    String coverUrl = '',
  }) async {
    try {
      final uid = _ownerUid;
      if (uid.isEmpty || !_canMutateOwnedHighlights) return null;

      final docRefId = DateTime.now().microsecondsSinceEpoch.toString();
      var resolvedCoverUrl = coverUrl.trim();
      if (resolvedCoverUrl.isNotEmpty && !looksLikeImageUrl(resolvedCoverUrl)) {
        resolvedCoverUrl = '';
      }
      if (resolvedCoverUrl.isEmpty && storyIds.isNotEmpty) {
        try {
          resolvedCoverUrl = await _resolveCoverUrlFromStoryIds(
            storyIds,
            highlightId: docRefId,
          );
        } catch (e, st) {
          debugPrint('StoryHighlights create cover resolve error: $e');
          debugPrintStack(stackTrace: st);
          resolvedCoverUrl = '';
        }
      }

      final model = StoryHighlightModel(
        id: docRefId,
        userId: uid,
        title: title,
        coverUrl: resolvedCoverUrl,
        storyIds: storyIds,
        createdAt: DateTime.now(),
        order: highlights.length,
      );

      await _repository.createHighlight(uid, model);
      highlights.add(model);
      try {
        await _repository.setHighlights(
          uid,
          List<StoryHighlightModel>.from(highlights),
        );
      } catch (e, st) {
        debugPrint('StoryHighlights create cache persist error: $e');
        debugPrintStack(stackTrace: st);
      }
      return model;
    } catch (e, st) {
      debugPrint('StoryHighlights create failed: $e');
      debugPrintStack(stackTrace: st);
      return null;
    }
  }

  Future<void> addStoryToHighlight(String highlightId, String storyId) async {
    try {
      final uid = _ownerUid;
      if (uid.isEmpty || !_canMutateOwnedHighlights) return;

      await _repository.addStoryToHighlight(
        uid,
        highlightId: highlightId,
        storyId: storyId,
      );

      final idx = highlights.indexWhere((h) => h.id == highlightId);
      if (idx != -1) {
        highlights[idx].storyIds.add(storyId);
        highlights.refresh();
        await _repository.setHighlights(
          uid,
          List<StoryHighlightModel>.from(highlights),
        );
      }
    } catch (_) {}
  }

  Future<void> deleteHighlight(String highlightId) async {
    try {
      final uid = _ownerUid;
      if (uid.isEmpty || !_canMutateOwnedHighlights) return;

      await _repository.deleteHighlight(
        uid,
        highlightId: highlightId,
      );

      highlights.removeWhere((h) => h.id == highlightId);
      await _repository.setHighlights(
        uid,
        List<StoryHighlightModel>.from(highlights),
      );
    } catch (_) {}
  }

  Future<void> updateHighlight(
    String highlightId,
    String title,
    String coverUrl,
  ) async {
    try {
      final uid = _ownerUid;
      if (uid.isEmpty || !_canMutateOwnedHighlights) return;

      await _repository.updateHighlight(
        uid,
        highlightId: highlightId,
        title: title,
        coverUrl: coverUrl,
      );

      final idx = highlights.indexWhere((h) => h.id == highlightId);
      if (idx != -1) {
        highlights[idx].title = title;
        highlights[idx].coverUrl = coverUrl;
        highlights.refresh();
        await _repository.setHighlights(
          uid,
          List<StoryHighlightModel>.from(highlights),
        );
      }
    } catch (_) {}
  }
}
