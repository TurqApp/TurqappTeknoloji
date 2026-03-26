part of 'about_profile_controller.dart';

class AboutProfileController extends _AboutProfileControllerBase {
  Future<void> getUserData(String userID) =>
      _loadAboutProfileUserData(this, userID);
}
