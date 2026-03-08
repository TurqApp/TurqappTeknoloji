import 'package:firebase_auth/firebase_auth.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';

class AdsAdminGuard {
  const AdsAdminGuard._();

  static Future<bool> canAccessAdsCenter() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return AdminAccessService.canManageSliders();
  }

  static bool canAccessAdsCenterSync() {
    return AdminAccessService.isKnownAdminSync();
  }

  static Future<String?> currentUidIfAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final ok = await canAccessAdsCenter();
    return ok ? user.uid : null;
  }
}
