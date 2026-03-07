import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_model.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:flutter/material.dart';

class DeletedStoriesController extends GetxController {
  RxList<StoryModel> list = <StoryModel>[].obs;
  DocumentSnapshot? lastDoc;
  RxBool hasMore = true.obs;
  RxBool isLoading = false.obs;
  final int pageSize = 40;
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

  Future<void> fetch({bool initial = false}) async {
    if (isLoading.value || (!initial && !hasMore.value)) return;
    isLoading.value = true;
    try {
      if (initial) {
        list.clear();
        lastDoc = null;
        hasMore.value = true;
        deletedAtById.clear();
        deleteReasonById.clear();
      }
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Güvenli sorgu: userId'e göre sırala ve client-side deleted filtresi uygula
      Query q = FirebaseFirestore.instance
          .collection('stories')
          .where('userId', isEqualTo: uid)
          .orderBy('createdDate', descending: true)
          .limit(pageSize);
      if (lastDoc != null) {
        q = (q as Query<Map<String, dynamic>>).startAfterDocument(lastDoc!);
      }
      final snap = await q.get();
      if (snap.docs.isEmpty) {
        hasMore.value = false;
        return;
      }
      lastDoc = snap.docs.last;

      final items = <StoryModel>[];
      for (final d in snap.docs) {
        final data = d.data() as Map<String, dynamic>;
        final isDeleted = (data['deleted'] ?? false) == true;
        if (isDeleted) {
          final m =
              StoryModel.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>);
          items.add(m);
          final delAt = (data['deletedAt'] ?? 0) as int;
          deletedAtById[m.id] = delAt;
          final reason = (data['deleteReason'] ?? '') as String;
          if (reason.isNotEmpty) deleteReasonById[m.id] = reason;
        }
      }
      list.addAll(items);
      if (snap.docs.length < pageSize) hasMore.value = false;
    } catch (e) {
      // Index problemlerinde fallback: sadece userId filtresiyle çekip client-side filtrele
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;
        final q = await FirebaseFirestore.instance
            .collection('stories')
            .where('userId', isEqualTo: uid)
            .orderBy('createdDate', descending: true)
            .limit(pageSize)
            .get();
        final items2 = <StoryModel>[];
        for (final d in q.docs) {
          final data = d.data();
          final isDeleted = (data['deleted'] ?? false) == true;
          if (isDeleted) {
            final m =
                StoryModel.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>);
            items2.add(m);
            final delAt = (data['deletedAt'] ?? 0) as int;
            deletedAtById[m.id] = delAt;
            final reason = (data['deleteReason'] ?? '') as String;
            if (reason.isNotEmpty) deleteReasonById[m.id] = reason;
          }
        }
        list.addAll(items2);
        if (q.docs.length < pageSize) hasMore.value = false;
      } catch (_) {}
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> restore(String storyId) async {
    await FirebaseFirestore.instance
        .collection('stories')
        .doc(storyId)
        .update({'deleted': false, 'deletedAt': 0});
    list.removeWhere((e) => e.id == storyId);
    deletedAtById.remove(storyId);
    // Dinamik: Hikaye satırını anlık tazele ve sahiplik bayrağını güncelle
    try {
      await StoryRowController.refreshStoriesGlobally();
    } catch (_) {}
  }

  @override
  Future<void> refresh() async {
    await fetch(initial: true);
  }

  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
