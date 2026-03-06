import 'package:firebase_auth/firebase_auth.dart';

class AdminAccessService {
  static const Set<String> adminUserIds = {
    "rlvJgi4VAoO7O78OwrooZc6puPW2",
  };

  static bool isKnownAdminSync() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return adminUserIds.contains(currentUid);
  }

  static Future<bool> canManageSliders() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    if (isKnownAdminSync()) return true;

    final token = await currentUser.getIdTokenResult(true);
    return token.claims?["admin"] == true;
  }
}
