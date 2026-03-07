import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_view.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Modules/JobFinder/JobDetails/job_details.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart';

import '../../Models/posts_model.dart';
import '../../Modules/Agenda/FloodListing/flood_listing.dart';
import '../../Modules/Agenda/SinglePost/single_post.dart';
import '../../Modules/Chat/chat.dart';
import '../../Modules/SocialProfile/social_profile.dart';

class NotifyReaderController extends GetxController {
  static const Duration _postLookupTtl = Duration(seconds: 30);
  static const Duration _chatLookupTtl = Duration(seconds: 30);
  static const Duration _jobLookupTtl = Duration(seconds: 30);
  static const Duration _tutoringLookupTtl = Duration(seconds: 30);
  static final Map<String, _CachedPostLookup> _postLookupCache =
      <String, _CachedPostLookup>{};
  static final Map<String, _CachedChatLookup> _chatLookupCache =
      <String, _CachedChatLookup>{};
  static final Map<String, _CachedJobLookup> _jobLookupCache =
      <String, _CachedJobLookup>{};
  static final Map<String, _CachedTutoringLookup> _tutoringLookupCache =
      <String, _CachedTutoringLookup>{};
  static const Duration _staleRetention = Duration(minutes: 3);
  static const int _maxLookupEntries = 300;

  Future<_CachedPostLookup> _getPostLookup(String postID) async {
    _pruneStaleLookups();
    final cached = _postLookupCache[postID];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _postLookupTtl) {
      return cached;
    }

    final doc =
        await FirebaseFirestore.instance.collection('Posts').doc(postID).get();
    final lookup = _CachedPostLookup(
      exists: doc.exists,
      model: doc.exists ? PostsModel.fromFirestore(doc) : null,
      cachedAt: DateTime.now(),
    );
    _postLookupCache[postID] = lookup;
    return lookup;
  }

  Future<_CachedChatLookup> _getChatLookup(String chatID) async {
    _pruneStaleLookups();
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final cacheKey = '${currentUid}_$chatID';
    final cached = _chatLookupCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _chatLookupTtl) {
      return cached;
    }
    if (currentUid.isEmpty) {
      return _CachedChatLookup(otherUser: '', cachedAt: DateTime.now());
    }

    final convDoc = await FirebaseFirestore.instance
        .collection("conversations")
        .doc(chatID)
        .get();

    String otherUser = '';
    if (convDoc.exists) {
      final participants = List<String>.from(convDoc.data()?["participants"] ?? []);
      otherUser = participants.firstWhere(
        (id) => id != currentUid,
        orElse: () => '',
      );
    }

    final lookup = _CachedChatLookup(
      otherUser: otherUser,
      cachedAt: DateTime.now(),
    );
    _chatLookupCache[cacheKey] = lookup;
    return lookup;
  }

  Future<_CachedJobLookup> _getJobLookup(String jobID) async {
    _pruneStaleLookups();
    final cached = _jobLookupCache[jobID];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _jobLookupTtl) {
      return cached;
    }
    final doc =
        await FirebaseFirestore.instance.collection('isBul').doc(jobID).get();
    final lookup = _CachedJobLookup(
      exists: doc.exists,
      model: doc.exists ? JobModel.fromMap(doc.data()!, doc.id) : null,
      cachedAt: DateTime.now(),
    );
    _jobLookupCache[jobID] = lookup;
    return lookup;
  }

  Future<_CachedTutoringLookup> _getTutoringLookup(String tutoringID) async {
    _pruneStaleLookups();
    final cached = _tutoringLookupCache[tutoringID];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _tutoringLookupTtl) {
      return cached;
    }
    final doc = await FirebaseFirestore.instance
        .collection('educators')
        .doc(tutoringID)
        .get();
    final lookup = _CachedTutoringLookup(
      exists: doc.exists,
      model: doc.exists ? TutoringModel.fromJson(doc.data()!, doc.id) : null,
      cachedAt: DateTime.now(),
    );
    _tutoringLookupCache[tutoringID] = lookup;
    return lookup;
  }

  /// Post detay sayfasına git, geri dönülürse NavBarView'e atla
  Future<void> goToPost(String postID) async {
    final lookup = await _getPostLookup(postID);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('Bilgi', 'Gönderi bulunamadı veya silinmiş.');
      return toNavbar();
    }
    final model = lookup.model!;
    if (model.deletedPost == true) {
      AppSnackbar('Bilgi', 'Gönderi kaldırılmış.');
      return toNavbar();
    }

    final route = (model.flood == false && model.floodCount > 1)
        ? Get.to<FloodListing>(() => FloodListing(mainModel: model))
        : Get.to<SinglePost>(
            () => SinglePost(model: model, showComments: false));

    route?.then((_) => toNavbar());
  }

  /// Post yorum sayfasına git, geri dönülürse NavBarView'e atla
  Future<void> goToPostComments(String postID) async {
    final lookup = await _getPostLookup(postID);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('Bilgi', 'Gönderi bulunamadı veya silinmiş.');
      return toNavbar();
    }
    final model = lookup.model!;
    if (model.deletedPost == true) {
      AppSnackbar('Bilgi', 'Gönderi kaldırılmış.');
      return toNavbar();
    }

    Get.to<SinglePost>(() => SinglePost(model: model, showComments: true))
        ?.then((_) => toNavbar());
  }

  /// Profil sayfasına git, geri dönülürse NavBarView'e atla
  Future<void> goToProfile(String userID) async {
    Get.to<SocialProfile>(() => SocialProfile(userID: userID))
        ?.then((_) => toNavbar());
  }

  /// Sohbet sayfasına git, geri dönülürse NavBarView'e atla
  Future<void> goToChat(String chatID) async {
    final lookup = await _getChatLookup(chatID);
    final otherUser = lookup.otherUser;

    if (otherUser.isEmpty) {
      AppSnackbar('Bilgi', 'Sohbet bulunamadı.');
      return toNavbar();
    }

    Get.to<ChatView>(() => ChatView(chatID: chatID, userID: otherUser))
        ?.then((_) => toNavbar());
  }

  Future<void> goToJob(String jobID) async {
    final lookup = await _getJobLookup(jobID);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('Bilgi', 'İlan bulunamadı veya kaldırılmış.');
      return toNavbar();
    }
    final model = lookup.model!;
    Get.to<JobDetails>(() => JobDetails(model: model))?.then((_) => toNavbar());
  }

  Future<void> goToTutoring(String tutoringID) async {
    final lookup = await _getTutoringLookup(tutoringID);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('Bilgi', 'Özel ders ilanı bulunamadı veya kaldırılmış.');
      return toNavbar();
    }
    final model = lookup.model!;
    Get.to<TutoringDetail>(() => TutoringDetail(), arguments: model)
        ?.then((_) => toNavbar());
  }

  /// NavBarView'e geç ve önceki sayfaları stack'ten at
  void toNavbar() {
    Get.offAll<NavBarView>(() => NavBarView());
  }

  void _pruneStaleLookups() {
    final now = DateTime.now();
    bool isStale(DateTime t) => now.difference(t) > _staleRetention;
    _postLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _chatLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _jobLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _tutoringLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _trimOldestIfNeeded();
  }

  void _trimOldestIfNeeded() {
    void trimMap<T>(
      Map<String, T> map,
      DateTime Function(T value) cachedAt,
    ) {
      if (map.length <= _maxLookupEntries) return;
      final entries = map.entries.toList()
        ..sort((a, b) => cachedAt(a.value).compareTo(cachedAt(b.value)));
      final removeCount = map.length - _maxLookupEntries;
      for (var i = 0; i < removeCount; i++) {
        map.remove(entries[i].key);
      }
    }

    trimMap<_CachedPostLookup>(_postLookupCache, (v) => v.cachedAt);
    trimMap<_CachedChatLookup>(_chatLookupCache, (v) => v.cachedAt);
    trimMap<_CachedJobLookup>(_jobLookupCache, (v) => v.cachedAt);
    trimMap<_CachedTutoringLookup>(_tutoringLookupCache, (v) => v.cachedAt);
  }
}

class _CachedPostLookup {
  final bool exists;
  final PostsModel? model;
  final DateTime cachedAt;

  const _CachedPostLookup({
    required this.exists,
    required this.model,
    required this.cachedAt,
  });
}

class _CachedChatLookup {
  final String otherUser;
  final DateTime cachedAt;

  const _CachedChatLookup({
    required this.otherUser,
    required this.cachedAt,
  });
}

class _CachedJobLookup {
  final bool exists;
  final JobModel? model;
  final DateTime cachedAt;

  const _CachedJobLookup({
    required this.exists,
    required this.model,
    required this.cachedAt,
  });
}

class _CachedTutoringLookup {
  final bool exists;
  final TutoringModel? model;
  final DateTime cachedAt;

  const _CachedTutoringLookup({
    required this.exists,
    required this.model,
    required this.cachedAt,
  });
}
