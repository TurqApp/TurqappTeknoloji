import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class PostLikeContentController extends GetxController {
  var fullName = "".obs;
  var pfImage = "".obs;
  var nickname = "".obs;

  Future<void> getUserData(String userID) async {
    FirebaseFirestore.instance
        .collection("users")
        .doc(userID)
        .get()
        .then((doc) {
      final data = doc.data() ?? const <String, dynamic>{};
      fullName.value =
          "${(data["firstName"] ?? "").toString()} ${(data["lastName"] ?? "").toString()}"
              .trim();
      pfImage.value = (data["avatarUrl"] ??
              data["pfImage"] ??
              data["photoURL"] ??
              data["profileImageUrl"] ??
              "")
          .toString();
      nickname.value =
          (data["displayName"] ?? data["username"] ?? data["nickname"] ?? "")
              .toString();
    });
  }
}
