import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class AdsAdminGuard {
  const AdsAdminGuard._();

  static Future<bool> canAccessAdsCenter() async {
    if (CurrentUserService.instance.userId.isEmpty) return false;
    return AdminAccessService.canAccessTask('ads_center');
  }

  static bool canAccessAdsCenterSync() {
    return AdminAccessService.isKnownAdminSync();
  }

  static Future<String?> currentUidIfAdmin() async {
    final ok = await canAccessAdsCenter();
    final uid = CurrentUserService.instance.userId;
    return ok && uid.isNotEmpty ? uid : null;
  }
}
