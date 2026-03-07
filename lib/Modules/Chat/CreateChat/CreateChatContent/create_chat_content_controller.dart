import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class CreateChatContentController extends GetxController {
  var nickname = "".obs;
  var fullName = "".obs;
  var avatarUrl = "".obs;
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
      final data = doc.data() ?? const <String, dynamic>{};
      nickname.value =
          (data["displayName"] ?? data["username"] ?? data["nickname"] ?? "")
              .toString();
      avatarUrl.value = (data["avatarUrl"] ??
              data["avatarUrl"] ??
              data["avatarUrl"] ??
              data["avatarUrl"] ??
              "")
          .toString();
      fullName.value =
          "${(data["firstName"] ?? "").toString()} ${(data["lastName"] ?? "").toString()}"
              .trim();
    });
  }
}
