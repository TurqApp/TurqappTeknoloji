import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class CreateChatContentController extends GetxController {
  var nickname = "".obs;
  var fullName = "".obs;
  var pfImage = "".obs;
  String userID;
  CreateChatContentController({required this.userID});
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
}
