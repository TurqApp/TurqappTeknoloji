import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class PostLikeContentController extends GetxController {
  var fullName = "".obs;
  var pfImage = "".obs;
  var nickname = "".obs;

  Future<void> getUserData(String userID) async {
    FirebaseFirestore.instance.collection("users").doc(userID)
        .get()
        .then((doc){
       fullName.value = "${doc.get("firstName")} ${doc.get("lastName")}";
       pfImage.value = doc.get("pfImage");
       nickname.value = doc.get("nickname");
    });
  }
}