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
    final doc = await FirebaseFirestore.instance
        .collection("Mesajlar")
        .doc(chatID)
        .get();

    final userID1 = doc.get("userID1") as String;
    final userID2 = doc.get("userID2") as String;
    final otherUser = (userID1 == currentUser) ? userID2 : userID1;

    Get.to<ChatView>(() => ChatView(chatID: chatID, userID: otherUser))
        ?.then((_) => toNavbar());
  }

  /// NavBarView'e geç ve önceki sayfaları stack'ten at
  void toNavbar() {
    Get.offAll<NavBarView>(() => NavBarView());
  }
}
