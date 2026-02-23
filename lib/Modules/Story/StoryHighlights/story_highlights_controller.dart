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

      final model = StoryHighlightModel(
        id: docRef.id,
        userId: uid,
        title: title,
        coverUrl: coverUrl,
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
}
