import 'package:get/get.dart';
import 'package:turqappv2/Modules/Profile/BecomeVerifiedAccount/become_verified_account.dart';

class VerifiedAccountNavigationService {
  const VerifiedAccountNavigationService();

  Future<T?> openBecomeVerifiedAccount<T>() {
    return Get.to<T>(() => const BecomeVerifiedAccount()) ?? Future<T?>.value();
  }
}
