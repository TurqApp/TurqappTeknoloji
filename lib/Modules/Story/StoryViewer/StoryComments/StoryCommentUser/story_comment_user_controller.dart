import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class StoryCommentUserController extends GetxController {
  var nickname = "".obs;
  var pfImage = "".obs;
  var fullName = "".obs;

  Future<void> getUserData(String userID) async {
    FirebaseFirestore.instance
        .collection("users")
        .doc(userID)
        .get()
        .then((doc) {
      nickname.value = doc.get("nickname");
      fullName.value = "${doc.get("firstName")} ${doc.get("lastName")}";
      pfImage.value = doc.get("pfImage");
    });
  }
}
