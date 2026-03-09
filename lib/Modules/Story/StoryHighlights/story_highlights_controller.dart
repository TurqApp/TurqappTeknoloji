import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'story_highlight_model.dart';

class StoryHighlightsController extends GetxController {
  final String userId;
  StoryHighlightsController({required this.userId});

  RxList<StoryHighlightModel> highlights = <StoryHighlightModel>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadHighlights();
  }

  Future<void> loadHighlights() async {
    try {
      isLoading.value = true;
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('highlights')
          .orderBy('order')
          .get();
      highlights.value =
          snap.docs.map((d) => StoryHighlightModel.fromDoc(d)).toList();
      await _hydrateMissingCoverUrls();
    } catch (e) {
      print('loadHighlights error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<StoryHighlightModel?> createHighlight({
    required String title,
    required List<String> storyIds,
    String coverUrl = '',
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('highlights')
          .doc();

      var resolvedCoverUrl = coverUrl.trim();
      if (resolvedCoverUrl.isEmpty && storyIds.isNotEmpty) {
        resolvedCoverUrl = await _resolveCoverUrlFromStoryIds(storyIds);
      }

      final model = StoryHighlightModel(
        id: docRef.id,
        userId: uid,
        title: title,
        coverUrl: resolvedCoverUrl,
        storyIds: storyIds,
        createdAt: DateTime.now(),
        order: highlights.length,
      );

      await docRef.set(model.toMap());
      highlights.add(model);
      return model;
    } catch (e) {
      print('createHighlight error: $e');
      return null;
    }
  }

  Future<void> addStoryToHighlight(String highlightId, String storyId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('highlights')
          .doc(highlightId)
          .update({
        'storyIds': FieldValue.arrayUnion([storyId]),
      });

      final idx = highlights.indexWhere((h) => h.id == highlightId);
      if (idx != -1) {
        highlights[idx].storyIds.add(storyId);
        highlights.refresh();
      }
    } catch (e) {
      print('addStoryToHighlight error: $e');
    }
  }

  Future<void> deleteHighlight(String highlightId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('highlights')
          .doc(highlightId)
          .delete();

      highlights.removeWhere((h) => h.id == highlightId);
    } catch (e) {
      print('deleteHighlight error: $e');
    }
  }

  Future<void> updateHighlight(
      String highlightId, String title, String coverUrl) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('highlights')
          .doc(highlightId)
          .update({'title': title, 'coverUrl': coverUrl});

      final idx = highlights.indexWhere((h) => h.id == highlightId);
      if (idx != -1) {
        highlights[idx].title = title;
        highlights[idx].coverUrl = coverUrl;
        highlights.refresh();
      }
    } catch (e) {
      print('updateHighlight error: $e');
    }
  }

  Future<void> _hydrateMissingCoverUrls() async {
    if (highlights.isEmpty) return;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final canPersist = currentUid != null && currentUid == userId;
    var anyLocalUpdate = false;

    for (var i = 0; i < highlights.length; i++) {
      final item = highlights[i];
      if (item.coverUrl.trim().isNotEmpty || item.storyIds.isEmpty) {
        continue;
      }
      final cover = await _resolveCoverUrlFromStoryIds(item.storyIds);
      if (cover.isEmpty) continue;

      item.coverUrl = cover;
      anyLocalUpdate = true;

      if (canPersist) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('highlights')
              .doc(item.id)
              .update({'coverUrl': cover});
        } catch (_) {}
      }
    }

    if (anyLocalUpdate) {
      highlights.refresh();
    }
  }

  Future<String> _resolveCoverUrlFromStoryIds(List<String> storyIds) async {
    for (final storyId in storyIds) {
      final doc = await FirebaseFirestore.instance
          .collection('stories')
          .doc(storyId)
          .get();
      if (!doc.exists) continue;
      final data = doc.data();
      if (data == null) continue;
      if ((data['deleted'] ?? false) == true) continue;
      final extracted = _extractPreviewUrlFromStoryData(data);
      if (extracted.isNotEmpty) return extracted;
    }
    return '';
  }

  String _extractPreviewUrlFromStoryData(Map<String, dynamic> data) {
    final elements = data['elements'];
    if (elements is List) {
      final asMaps = elements
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry('$k', v)))
          .toList();

      // 1) Image/GIF iceriklerini onceliklendir.
      for (final m in asMaps) {
        final type = (m['type'] ?? '').toString().toLowerCase();
        final content = (m['content'] ?? '').toString().trim();
        if (content.isEmpty) continue;
        if ((type == 'image' || type == 'gif') && _isLikelyImageUrl(content)) {
          return content;
        }
      }

      // 2) Bilinen thumbnail alanlari.
      for (final m in asMaps) {
        final thumb = (m['thumbnail'] ??
                m['thumbnailUrl'] ??
                m['thumbUrl'] ??
                m['previewUrl'] ??
                m['coverUrl'] ??
                '')
            .toString()
            .trim();
        if (_isLikelyImageUrl(thumb)) return thumb;
      }

      // 3) Herhangi bir image URL.
      for (final m in asMaps) {
        final content = (m['content'] ?? '').toString().trim();
        if (_isLikelyImageUrl(content)) return content;
      }
    }

    final topLevelThumb = (data['thumbnail'] ??
            data['thumbnailUrl'] ??
            data['thumbUrl'] ??
            data['previewUrl'] ??
            data['coverUrl'] ??
            '')
        .toString()
        .trim();
    if (_isLikelyImageUrl(topLevelThumb)) return topLevelThumb;
    return '';
  }

  bool _isLikelyImageUrl(String url) {
    final value = url.trim().toLowerCase();
    if (value.isEmpty) return false;
    return value.contains('.jpg') ||
        value.contains('.jpeg') ||
        value.contains('.png') ||
        value.contains('.webp') ||
        value.contains('.gif') ||
        value.contains('thumbnail') ||
        value.contains('thumb');
  }
}
