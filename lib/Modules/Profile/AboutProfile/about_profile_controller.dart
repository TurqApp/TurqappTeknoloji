import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class AboutProfileController extends GetxController {
  // 🎯 Using CurrentUserService for optimized access
  final userService = CurrentUserService.instance;

  var avatarUrl = "".obs;
  var nickname = "".obs;
  var fullName = "".obs;
  var createdDate = "".obs;

  Future<void> getUserData(String userID) async {
    try {
      // 🎯 If viewing own profile, use cache (instant!)
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == userID && userService.currentUser != null) {
        final user = userService.currentUser!;
        avatarUrl.value = user.avatarUrl;
        nickname.value = user.nickname;
        createdDate.value = user.createdDate;
        fullName.value = user.fullName;
        return;
      }

      // For other users, fetch from Firebase
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userID)
          .get();

      if (!doc.exists) return;

      final data = doc.data() ?? {};

      avatarUrl.value = (data["avatarUrl"] ??
              data["avatarUrl"] ??
              data["avatarUrl"] ??
              data["avatarUrl"] ??
              "")
          .toString();
      nickname.value =
          (data["nickname"] ?? data["username"] ?? data["displayName"] ?? "")
              .toString();
      createdDate.value =
          data.containsKey("createdDate") ? data["createdDate"] ?? "" : "";
      fullName.value =
          "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}".trim();
    } catch (e) {
      print("Profil verisi alınamadı: $e");
    }
  }
}
