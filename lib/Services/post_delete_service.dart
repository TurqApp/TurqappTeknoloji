import 'package:cloud_firestore/cloud_firestore.dart';

import '../Models/posts_model.dart';
import '../Core/Repositories/post_repository.dart';
import '../Core/Repositories/user_repository.dart';
import '../Core/Services/IndexPool/index_pool_store.dart';
import '../Core/Services/agenda_shuffle_cache_service.dart';
import '../Core/Services/typesense_post_service.dart';
import '../Core/Repositories/profile_repository.dart';
import '../Modules/Agenda/agenda_controller.dart';
import '../Modules/Explore/explore_controller.dart';
import '../Modules/Profile/MyProfile/profile_controller.dart';
import '../Modules/Short/short_controller.dart';
import '../Services/current_user_service.dart';

/// Uygulama genelinde gönderi silme (soft delete) işlemini merkezileştirir.
///
/// - Firestore: Posts/{docID} üzerinde `deletedPost: true` ve
///   `deletedPostTime: now` alanlarını günceller.
/// - Sayaç: Görünür kök gönderi ve sahibi ise `counterOfPosts` değerini 1 azaltır.
/// - UI/Store: Tüm ilgili listelerde modelin `deletedPost` alanını true yapar
///   (yalnızca runtime; Firestore'a yazmaz) ve listeleri refresh eder.
class PostDeleteService {
  PostDeleteService._();
  static PostDeleteService? _instance;
  static PostDeleteService? maybeFind() => _instance;

  static PostDeleteService ensure() =>
      maybeFind() ?? (_instance = PostDeleteService._());

  static PostDeleteService get instance => ensure();

  Future<void> softDelete(PostsModel model) async {
    final firestore = FirebaseFirestore.instance;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final postRef = firestore.collection('Posts').doc(model.docID);
    // Ön kontrol: daha önce silinmiş mi?
    bool alreadyDeleted = false;
    try {
      final preSnap = await postRef.get();
      alreadyDeleted = (preSnap.data()?['deletedPost'] ?? false) == true;
    } catch (_) {}

    // 1) Firestore soft delete
    await postRef.update({
      'deletedPost': true,
      'deletedPostTime': nowMs,
    });

    // 2) Sayaç: görünür bir kök post ise ve sahibi isek counterOfPosts -=1
    try {
      final me = CurrentUserService.instance.effectiveUserId;
      final isVisibleRoot = (model.timeStamp <= nowMs) && !model.flood;
      if (me.isNotEmpty && model.userID == me && isVisibleRoot) {
        await UserRepository.ensure().updateUserFields(
          me,
          {'counterOfPosts': FieldValue.increment(-1)},
          mergeIntoCache: false,
        );
      }
    } catch (_) {}

    // 3) UI/Store tarafını güncelle
    _updateStores(model.docID);
    PostRepository.ensure().mergeCachedPostData(model.docID, {
      'deletedPost': true,
      'deletedPostTime': nowMs,
    });
    await ProfileRepository.ensure().removePostFromCaches(
      uid: model.userID,
      docId: model.docID,
    );
    await _invalidatePostCaches(<String>[model.docID]);

    // 3.5) Bu gönderi yeniden paylaşıldıysa, tüm yeniden paylaşılan kopyaları kaldır
    try {
      await _cascadeDeleteReshares(model.docID);
    } catch (e) {
      // Sessiz geç
      print('Cascade delete reshares error: $e');
    }

    try {
      await _cascadeDeleteSharedAs(model.docID);
    } catch (e) {
      print('Cascade delete shared-as error: $e');
    }

    // 4) Bu gönderiye ait beğeniler toplamını sahibi üzerinden düş (idempotent)
    if (!alreadyDeleted) {
      await _decrementOwnerLikeCounter(model);
    }
  }

  Future<void> _cascadeDeleteReshares(String originalPostID) async {
    final firestore = FirebaseFirestore.instance;
    final mappingCol = firestore
        .collection('Posts')
        .doc(originalPostID)
        .collection('reshares');

    final snap = await mappingCol.get();
    if (snap.docs.isEmpty) return;

    for (var i = 0; i < snap.docs.length; i += 400) {
      final batch = firestore.batch();
      for (final d in snap.docs.skip(i).take(400)) {
        final uid = d.id;
        batch.delete(
          firestore
              .collection('users')
              .doc(uid)
              .collection('reshared_posts')
              .doc(originalPostID),
        );
        batch.delete(mappingCol.doc(uid));
      }
      await batch.commit();
    }
  }

  Future<void> _cascadeDeleteSharedAs(String originalPostID) async {
    final firestore = FirebaseFirestore.instance;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final sharedSnap = await firestore
        .collection('Posts')
        .where('originalPostID', isEqualTo: originalPostID)
        .where('sharedAsPost', isEqualTo: true)
        .get();

    final postSharersSnap = await firestore
        .collection('Posts')
        .doc(originalPostID)
        .collection('postSharers')
        .get();

    final Set<String> sharedPostIds = {
      ...sharedSnap.docs.where((doc) {
        final data = doc.data();
        return (data['quotedPost'] ?? false) != true;
      }).map((doc) => doc.id),
      ...postSharersSnap.docs
          .where((doc) => (doc.data()['quotedPost'] ?? false) != true)
          .map((doc) => (doc.data()['sharedPostID'] ?? '').toString().trim())
          .where((id) => id.isNotEmpty),
    };

    final refs = sharedPostIds
        .map((sharedPostId) => firestore.collection('Posts').doc(sharedPostId))
        .toList(growable: false);
    for (var i = 0; i < refs.length; i += 400) {
      final batch = firestore.batch();
      for (final ref in refs.skip(i).take(400)) {
        batch.set(
            ref,
            {
              'deletedPost': true,
              'deletedPostTime': nowMs,
            },
            SetOptions(merge: true));
      }
      await batch.commit();
    }

    for (final sharedPostId in sharedPostIds) {
      _updateStores(sharedPostId);
      PostRepository.ensure().mergeCachedPostData(sharedPostId, {
        'deletedPost': true,
        'deletedPostTime': nowMs,
      });
    }
    await _invalidatePostCaches(sharedPostIds);

    for (var i = 0; i < postSharersSnap.docs.length; i += 400) {
      final batch = firestore.batch();
      for (final doc in postSharersSnap.docs.skip(i).take(400)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  void _updateStores(String docID) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Agenda akışı
    final agenda = AgendaController.maybeFind();
    if (agenda != null) {
      agenda.agendaList.removeWhere((e) => e.docID == docID);
      agenda.mergedFeedEntries
          .removeWhere((entry) => (entry['postId'] ?? entry['docID']) == docID);
      agenda.filteredFeedEntries
          .removeWhere((entry) => (entry['postId'] ?? entry['docID']) == docID);
      agenda.highlightDocIDs.remove(docID);
      agenda.agendaList.refresh();
      agenda.mergedFeedEntries.refresh();
      agenda.filteredFeedEntries.refresh();
    }

    // Explore listeleri
    final explore = ExploreController.maybeFind();
    if (explore != null) {
      final i1 = explore.explorePosts.indexWhere((e) => e.docID == docID);
      if (i1 != -1) {
        explore.explorePosts[i1] = explore.explorePosts[i1]
            .copyWith(deletedPost: true, deletedPostTime: now);
      }
      final i2 = explore.explorePhotos.indexWhere((e) => e.docID == docID);
      if (i2 != -1) {
        explore.explorePhotos[i2] = explore.explorePhotos[i2]
            .copyWith(deletedPost: true, deletedPostTime: now);
      }
      final i3 = explore.exploreVideos.indexWhere((e) => e.docID == docID);
      if (i3 != -1) {
        explore.exploreVideos[i3] = explore.exploreVideos[i3]
            .copyWith(deletedPost: true, deletedPostTime: now);
      }
      // Floods listesi
      final i4 = explore.exploreFloods.indexWhere((e) => e.docID == docID);
      if (i4 != -1) {
        explore.exploreFloods[i4] = explore.exploreFloods[i4]
            .copyWith(deletedPost: true, deletedPostTime: now);
      }
      explore.explorePosts.refresh();
      explore.explorePhotos.refresh();
      explore.exploreVideos.refresh();
      explore.exploreFloods.refresh();
    }

    // Profil listeleri
    final prof = ProfileController.maybeFind();
    if (prof != null) {
      prof.allPosts.removeWhere((e) => e.docID == docID);
      prof.photos.removeWhere((e) => e.docID == docID);
      prof.videos.removeWhere((e) => e.docID == docID);
      prof.scheduledPosts.removeWhere((e) => e.docID == docID);
      prof.reshares.removeWhere((e) => e.docID == docID);
      prof.allPosts.refresh();
      prof.photos.refresh();
      prof.videos.refresh();
      prof.scheduledPosts.refresh();
      prof.reshares.refresh();
    }

    // Shorts listesi
    final shorts = ShortController.maybeFind();
    if (shorts != null) {
      shorts.shorts.removeWhere((e) => e.docID == docID);
      shorts.shorts.refresh();
    }
  }

  Future<void> _invalidatePostCaches(Iterable<String> docIds) async {
    final ids = docIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (ids.isEmpty) return;

    try {
      final pool = IndexPoolStore.maybeFind();
      if (pool != null) {
        for (final kind in const <IndexPoolKind>[
          IndexPoolKind.feed,
          IndexPoolKind.explore,
          IndexPoolKind.shortFullscreen,
        ]) {
          await pool.removePosts(kind, ids.toList(growable: false));
        }
      }
    } catch (_) {}

    try {
      AgendaShuffleCacheService.maybeFind()?.removePosts(ids);
    } catch (_) {}

    for (final docId in ids) {
      try {
        await TypesensePostService.ensure().invalidatePostId(docId);
      } catch (_) {}
    }
  }

  Future<void> _decrementOwnerLikeCounter(PostsModel model) async {
    try {
      // Gönderiye ait toplam beğeni sayısı
      final likesColl = FirebaseFirestore.instance
          .collection('Posts')
          .doc(model.docID)
          .collection('likes');

      int likeCount = 0;
      try {
        final agg = await likesColl.count().get();
        likeCount = (agg.count ?? 0);
      } catch (_) {
        // Eski SDK'larda count() yoksa fallback
        final qs = await likesColl.get();
        likeCount = qs.docs.length;
      }

      if (likeCount <= 0) return;

      final userRef =
          FirebaseFirestore.instance.collection('users').doc(model.userID);
      final userSnap = await userRef.get();
      final currentCount = (userSnap.data()?['counterOfLikes'] ?? 0) as int;
      final dec = likeCount > currentCount ? currentCount : likeCount;
      if (dec > 0) {
        await UserRepository.ensure().updateUserFields(
          model.userID,
          {'counterOfLikes': FieldValue.increment(-dec)},
          mergeIntoCache: false,
        );
      }
    } catch (_) {}
  }
}
