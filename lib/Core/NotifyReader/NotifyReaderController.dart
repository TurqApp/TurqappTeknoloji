import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/NavBar/NavBarView.dart';

import '../../Models/PostsModel.dart';
import '../../Modules/Agenda/FloodListing/FloodListing.dart';
import '../../Modules/Agenda/SinglePost/SinglePost.dart';
import '../../Modules/Chat/Chat.dart';
import '../../Modules/SocialProfile/SocialProfile.dart';

class NotifyReaderController extends GetxController {
  /// Post detay sayfasına git, geri dönülürse NavBarView'e atla
  Future<void> goToPost(String postID) async {
    final doc =
        await FirebaseFirestore.instance.collection('Posts').doc(postID).get();
    if (!doc.exists) {
      AppSnackbar('Bilgi', 'Gönderi bulunamadı veya silinmiş.');
      return toNavbar();
    }
    final model = PostsModel.fromFirestore(doc);
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
    final doc =
        await FirebaseFirestore.instance.collection('Posts').doc(postID).get();
    if (!doc.exists) {
      AppSnackbar('Bilgi', 'Gönderi bulunamadı veya silinmiş.');
      return toNavbar();
    }
    final model = PostsModel.fromFirestore(doc);
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
      final legacyDoc = await FirebaseFirestore.instance
          .collection("message")
          .doc(chatID)
          .get();
      if (!legacyDoc.exists) {
        AppSnackbar('Bilgi', 'Sohbet bulunamadı.');
        return toNavbar();
      }
      final userID1 = legacyDoc.get("userID1") as String;
      final userID2 = legacyDoc.get("userID2") as String;
      otherUser = (userID1 == currentUser) ? userID2 : userID1;
    }

    Get.to<ChatView>(() => ChatView(chatID: chatID, userID: otherUser))
        ?.then((_) => toNavbar());
  }

  /// NavBarView'e geç ve önceki sayfaları stack'ten at
  void toNavbar() {
    Get.offAll<NavBarView>(() => NavBarView());
  }
}
