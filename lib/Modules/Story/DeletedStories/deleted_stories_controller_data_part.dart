part of 'deleted_stories_controller.dart';

extension DeletedStoriesControllerDataPart on DeletedStoriesController {
  Future<bool> _restoreFromCache(String uid) async {
    try {
      final restored = await _storyRepository.restoreDeletedStoriesCache(uid);
      if (restored == null || restored.stories.isEmpty) return false;
      list.assignAll(restored.stories);
      deletedAtById.assignAll(restored.deletedAtById);
      deleteReasonById.assignAll(restored.deleteReasonById);
      return true;
    } catch (e) {
      debugPrint('Deleted stories cache restore error: $e');
      return false;
    }
  }

  Future<void> _persistCache(String uid) async {
    try {
      await _storyRepository.persistDeletedStoriesCache(
        uid: uid,
        stories: list.toList(growable: false),
        deletedAtById: deletedAtById,
        deleteReasonById: deleteReasonById,
      );
    } catch (e) {
      debugPrint('Deleted stories cache persist error: $e');
    }
  }

  Future<void> fetch({bool initial = false, bool forceRemote = false}) async {
    if (isLoading.value) return;
    if (!forceRemote) {
      isLoading.value = true;
    }
    try {
      final uid = _currentUid;
      if (uid.isEmpty) return;

      if (initial) {
        final restored = await _restoreFromCache(uid);
        if (restored && !forceRemote) {
          isLoading.value = false;
          Future<void>.delayed(Duration.zero, () => fetch(forceRemote: true));
          return;
        }
      }

      final payload = await _storyRepository.fetchDeletedStories(uid);
      debugPrint(
        'DeletedStoriesController.fetch: items=${payload.stories.length} '
        'reasons=${payload.deleteReasonById.length}',
      );
      list.assignAll(payload.stories);
      deletedAtById.assignAll(payload.deletedAtById);
      deleteReasonById.assignAll(payload.deleteReasonById);
      await _persistCache(uid);
    } catch (e) {
      debugPrint('Deleted stories fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> restore(String storyId) async {
    final data =
        await _storyRepository.getStoryRaw(storyId, preferCache: true) ??
            const <String, dynamic>{};
    await _storyRepository.restoreDeletedStory(storyId);
    final musicId = (data['musicId'] ?? '').toString().trim();
    if (musicId.isNotEmpty) {
      await StoryMusicLibraryService.instance.restoreStoryUsage(
        musicId: musicId,
        storyId: storyId,
        userId: (data['userId'] ?? '').toString().trim(),
        createdAt: (data['createdDate'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
        title: (data['musicTitle'] ?? '').toString().trim(),
        artist: (data['musicArtist'] ?? '').toString().trim(),
        audioUrl: (data['musicUrl'] ?? '').toString().trim(),
        coverUrl: (data['musicCoverUrl'] ?? '').toString().trim(),
      );
    }
    list.removeWhere((e) => e.id == storyId);
    deletedAtById.remove(storyId);
    deleteReasonById.remove(storyId);
    final uid = _currentUid;
    if (uid.isNotEmpty) {
      await _persistCache(uid);
    }
    try {
      await refreshStoryRowGlobally();
    } catch (_) {}
  }

  Future<void> repost(StoryModel story) async {
    final storyId = await _storyRepository.repostDeletedStory(story);
    if (storyId.isEmpty) return;
    try {
      await refreshStoryRowGlobally();
    } catch (_) {}
  }

  Future<void> deleteForever(StoryModel story) async {
    await _storyRepository.permanentlyDeleteStory(story.id);
    list.removeWhere((e) => e.id == story.id);
    deletedAtById.remove(story.id);
    deleteReasonById.remove(story.id);
    final uid = _currentUid;
    if (uid.isNotEmpty) {
      await _persistCache(uid);
    }
    try {
      await refreshStoryRowGlobally();
    } catch (_) {}
  }
}
