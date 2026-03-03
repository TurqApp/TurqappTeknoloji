import 'package:firebase_auth/firebase_auth.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class AdminAccessService {
  static const Set<String> adminUserIds = {
    "jp4ZnrD0CpX7VYkDNTGHeZvgwYA2",
    "hiv3UzAABlRWJaePerm3mtPEolI3",
  };

  static const Set<String> adminNicknames = {
    "osmannafiz",
    "turqapp",
  };

  static bool isKnownAdminSync() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final currentNickname =
        CurrentUserService.instance.nickname.trim().toLowerCase();
    return adminUserIds.contains(currentUid) ||
        adminNicknames.contains(currentNickname);
  }

  static Future<bool> canManageSliders() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    if (isKnownAdminSync()) return true;

    final token = await currentUser.getIdTokenResult(true);
    return token.claims?["admin"] == true;
  }
}
