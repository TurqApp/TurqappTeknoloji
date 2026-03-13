import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Services/story_music_library_service.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_model.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:flutter/material.dart';

class DeletedStoriesController extends GetxController {
  RxList<StoryModel> list = <StoryModel>[].obs;
  RxBool isLoading = false.obs;
  // Silinme zamanı bilgisi (ms) – UI'da göstermek için
  final RxMap<String, int> deletedAtById = <String, int>{}.obs;
  final RxMap<String, String> deleteReasonById = <String, String>{}.obs;
  // UI paging
  final PageController pageController = PageController();
  final StoryRepository _storyRepository = StoryRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    fetch(initial: true);
  }

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
    isLoading.value = true;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      if (initial) {
        final restored = await _restoreFromCache(uid);
        if (restored && !forceRemote) {
          Future<void>.delayed(Duration.zero, () => fetch(forceRemote: true));
          return;
        }
      }

      list.clear();
      deletedAtById.clear();
      deleteReasonById.clear();
      final payload = await _storyRepository.fetchDeletedStories(uid);
      debugPrint(
        'DeletedStoriesController.fetch: uid=$uid items=${payload.stories.length} '
        'reasons=${payload.deleteReasonById}',
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
    final data = await _storyRepository.getStoryRaw(storyId, preferCache: true) ??
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _persistCache(uid);
    }
    // Dinamik: Hikaye satırını anlık tazele ve sahiplik bayrağını güncelle
    try {
      await StoryRowController.refreshStoriesGlobally();
    } catch (_) {}
  }

  @override
  Future<void> refresh() async {
    await fetch(initial: false, forceRemote: true);
  }

  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
