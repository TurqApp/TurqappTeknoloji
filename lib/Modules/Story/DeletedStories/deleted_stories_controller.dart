import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/story_music_library_service.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_model.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class DeletedStoriesController extends GetxController {
  static const int _cacheLimit = 100;
  static const Duration _cacheTtl = Duration(hours: 12);

  RxList<StoryModel> list = <StoryModel>[].obs;
  RxBool isLoading = false.obs;
  // Silinme zamanı bilgisi (ms) – UI'da göstermek için
  final RxMap<String, int> deletedAtById = <String, int>{}.obs;
  final RxMap<String, String> deleteReasonById = <String, String>{}.obs;
  // UI paging
  final PageController pageController = PageController();

  @override
  void onInit() {
    super.onInit();
    fetch(initial: true);
  }

  String _cacheKey(String uid) => 'deleted_stories_cache_v1_$uid';

  Future<bool> _restoreFromCache(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(uid));
      if (raw == null || raw.isEmpty) return false;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return false;
      final savedAtMs = (decoded['savedAt'] as num?)?.toInt() ?? 0;
      if (savedAtMs <= 0) return false;
      final cacheAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(savedAtMs),
      );
      if (cacheAge > _cacheTtl) return false;
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
        restoredDeletedAt[story.id] =
            (map['deletedAt'] as num?)?.toInt() ?? 0;
        final reason = (map['deleteReason'] ?? '').toString();
        if (reason.isNotEmpty) restoredReasons[story.id] = reason;
      }
      if (restoredStories.isEmpty) return false;
      list.assignAll(restoredStories);
      deletedAtById.assignAll(restoredDeletedAt);
      deleteReasonById.assignAll(restoredReasons);
      return true;
    } catch (e) {
      debugPrint('Deleted stories cache restore error: $e');
      return false;
    }
  }

  Future<void> _persistCache(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = list
          .map((story) => <String, dynamic>{
                'story': story.toCacheMap(),
                'deletedAt': deletedAtById[story.id] ?? 0,
                'deleteReason': deleteReasonById[story.id] ?? '',
              })
          .toList();
      await prefs.setString(
        _cacheKey(uid),
        jsonEncode({
          'savedAt': DateTime.now().millisecondsSinceEpoch,
          'items': items,
        }),
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
          return;
        }
      }

      list.clear();
      deletedAtById.clear();
      deleteReasonById.clear();

      // Bu ekranda güvenilirlik öncelikli: kullanıcının tüm hikayelerini çekip
      // silinmiş/süresi bitmiş filtrelerini client-side uygula.
      final snap = await FirebaseFirestore.instance
          .collection('stories')
          .where('userId', isEqualTo: uid)
          .get();

      final items = <StoryModel>[];
      for (final d in snap.docs) {
        final data = d.data();
        final isDeleted = (data['deleted'] ?? false) == true;
        if (isDeleted) {
          final m =
              StoryModel.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>);
          items.add(m);
          final delAt = (data['deletedAt'] ?? 0) is num
              ? ((data['deletedAt'] ?? 0) as num).toInt()
              : 0;
          deletedAtById[m.id] = delAt;
          final reason = (data['deleteReason'] ?? '').toString();
          if (reason.isNotEmpty) deleteReasonById[m.id] = reason;
        }
      }
      items.sort((a, b) {
        final aDeletedAt = deletedAtById[a.id] ?? 0;
        final bDeletedAt = deletedAtById[b.id] ?? 0;
        return bDeletedAt.compareTo(aDeletedAt);
      });
      if (items.length > _cacheLimit) {
        final trimmed = items.take(_cacheLimit).toList();
        final keptIds = trimmed.map((e) => e.id).toSet();
        deletedAtById.removeWhere((key, _) => !keptIds.contains(key));
        deleteReasonById.removeWhere((key, _) => !keptIds.contains(key));
        list.assignAll(trimmed);
      } else {
        list.assignAll(items);
      }
      await _persistCache(uid);
    } catch (e) {
      debugPrint('Deleted stories fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> restore(String storyId) async {
    final storyDoc = await FirebaseFirestore.instance
        .collection('stories')
        .doc(storyId)
        .get();
    final data = storyDoc.data() ?? const <String, dynamic>{};
    await FirebaseFirestore.instance.collection('stories').doc(storyId).update({
      'deleted': false,
      'deletedAt': 0,
      'deleteReason': FieldValue.delete(),
    });
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
