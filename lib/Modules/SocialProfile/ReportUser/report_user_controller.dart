import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';

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
  var avatarUrl = "".obs;
  var fullName = "".obs;
  var selectedTitle = "".obs;
  var selectedDesc = "".obs;
  var blockedUser = false.obs;
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await _userRepository.getUserRaw(userID);
    if (data == null) return;
    nickname.value =
        (data["nickname"] ?? data["username"] ?? data["displayName"] ?? "")
            .toString();
    avatarUrl.value = resolveAvatarUrl(data);
    fullName.value =
        "${(data["firstName"] ?? "").toString()} ${(data["lastName"] ?? "").toString()}"
            .trim();
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
    final blockedEntries = await _userSubcollectionRepository.getEntries(
      userID,
      subcollection: "blockedUsers",
      preferCache: true,
    );
    final exists = blockedEntries.any((entry) => entry.id == currentUserID);
    if (exists) {
      await _userSubcollectionRepository.deleteEntry(
        userID,
        subcollection: "blockedUsers",
        docId: currentUserID,
      );
      blockedUser.value = false;
      return;
    }

    await _userSubcollectionRepository.upsertEntry(
      userID,
      subcollection: "blockedUsers",
      docId: currentUserID,
      data: {
        "userID": currentUserID,
        "updatedDate": DateTime.now().millisecondsSinceEpoch,
      },
    );
    blockedUser.value = true;
  }
}
