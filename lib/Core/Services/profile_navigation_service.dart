import 'package:get/get.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_view.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';

class ProfileNavigationService {
  const ProfileNavigationService();

  Future<void> openMyProfile() async {
    await Get.to(() => const ProfileView());
  }

  Future<void> openSocialProfile(
    String userId, {
    bool preventDuplicates = true,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;
    await Get.to(
      () => SocialProfile(userID: normalizedUserId),
      preventDuplicates: preventDuplicates,
    );
  }
}
