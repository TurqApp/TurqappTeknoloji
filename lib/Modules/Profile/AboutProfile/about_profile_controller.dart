import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class AboutProfileController extends GetxController {
  // 🎯 Using CurrentUserService for optimized access
  final userService = CurrentUserService.instance;
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

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
      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (summary != null) {
        avatarUrl.value = summary.avatarUrl;
        nickname.value = summary.nickname;
        fullName.value = summary.displayName;
      }
      final data = await _userRepository.getUserRaw(
        userID,
        preferCache: true,
        cacheOnly: true,
      );
      if (data == null) return;
      createdDate.value =
          data.containsKey("createdDate") ? data["createdDate"] ?? "" : "";
      if (fullName.value.trim().isEmpty) {
        fullName.value =
            "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}".trim();
      }
    } catch (_) {
    }
  }
}
