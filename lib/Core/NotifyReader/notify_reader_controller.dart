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
  static final Map<String, _CachedPostLookup> _postLookupCache =
      <String, _CachedPostLookup>{};

  Future<_CachedPostLookup> _getPostLookup(String postID) async {
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
    final currentUser = FirebaseAuth.instance.currentUser?.uid;
    String otherUser = "";

    final convDoc = await FirebaseFirestore.instance
        .collection("conversations")
        .doc(chatID)
        .get();

    if (convDoc.exists) {
      final participants =
          List<String>.from(convDoc.data()?["participants"] ?? []);
      otherUser = participants.firstWhere(
        (id) => id != currentUser,
        orElse: () => "",
      );
    }

    if (otherUser.isEmpty) {
      AppSnackbar('Bilgi', 'Sohbet bulunamadı.');
      return toNavbar();
    }

    Get.to<ChatView>(() => ChatView(chatID: chatID, userID: otherUser))
        ?.then((_) => toNavbar());
  }

  Future<void> goToJob(String jobID) async {
    final doc =
        await FirebaseFirestore.instance.collection('isBul').doc(jobID).get();
    if (!doc.exists) {
      AppSnackbar('Bilgi', 'İlan bulunamadı veya kaldırılmış.');
      return toNavbar();
    }
    final model = JobModel.fromMap(doc.data()!, doc.id);
    Get.to<JobDetails>(() => JobDetails(model: model))?.then((_) => toNavbar());
  }

  Future<void> goToTutoring(String tutoringID) async {
    final doc = await FirebaseFirestore.instance
        .collection('educators')
        .doc(tutoringID)
        .get();
    if (!doc.exists) {
      AppSnackbar('Bilgi', 'Özel ders ilanı bulunamadı veya kaldırılmış.');
      return toNavbar();
    }
    final model = TutoringModel.fromJson(doc.data()!, doc.id);
    Get.to<TutoringDetail>(() => TutoringDetail(), arguments: model)
        ?.then((_) => toNavbar());
  }

  /// NavBarView'e geç ve önceki sayfaları stack'ten at
  void toNavbar() {
    Get.offAll<NavBarView>(() => NavBarView());
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
