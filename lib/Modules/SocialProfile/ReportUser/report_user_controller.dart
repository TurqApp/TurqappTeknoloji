import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

class ReportUserController extends GetxController {
  String userID;
  String postID;
  String commentID;
  ReportUserController({
    required this.userID,
    required this.postID,
    required this.commentID,
  });

  var step = 0.50.obs;
  var nickname = "".obs;
  var pfImage = "".obs;
  var fullName = "".obs;
  var selectedTitle = "".obs;
  var selectedDesc = "".obs;
  var blockedUser = false.obs;

  @override
  void onInit() {
    super.onInit();
    FirebaseFirestore.instance
        .collection("users")
        .doc(userID)
        .get()
        .then((doc) {
      nickname.value = doc.get("nickname");
      pfImage.value = doc.get("pfImage");
      fullName.value = "${doc.get("firstName")} ${doc.get("lastName")}";
    });
  }

  Future<void> report() async {
    FirebaseFirestore.instance.collection("reports").add({
      "userID": userID,
      "postID": postID,
      "timeStamp": DateTime.now().millisecondsSinceEpoch,
      "sikayetTitle": selectedTitle.value,
      "sikayetDesc": selectedDesc.value,
      "yorumID": commentID
    });

    Get.back();

    AppSnackbar("Talebiniz Bize Ulaştı!",
        "${nickname.value} kullanıcısını inceleme altına alacağız. Talebinizden dolayı teşekkür ederiz");
  }

  Future<void> block() async {
    final currentUserID = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance.collection("users").doc(userID);

    // Öncelikle belgeyi çekiyoruz.
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      final data = snapshot.data();
      final blockedUsers = List<String>.from(data?["blockedUsers"] ?? []);

      // Eğer mevcut kullanıcı ID'si blockedUsers'da varsa, kaldır.
      if (blockedUsers.contains(currentUserID)) {
        await docRef.update({
          "blockedUsers": FieldValue.arrayRemove([currentUserID])
        });
      } else {
        // Aksi halde ekle.
        await docRef.update({
          "blockedUsers": FieldValue.arrayUnion([currentUserID])
        });
      }
      blockedUser.value = true;
    } else {
      // Eğer belge yoksa hata fırlatabilir veya yeni bir belge oluşturabilirsiniz.
      print("Belge bulunamadı.");
    }
  }
}
