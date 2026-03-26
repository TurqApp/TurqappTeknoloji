part of 'edit_profile_controller.dart';

extension EditProfileControllerFacadePart on EditProfileController {
  String get _currentUid => userService.effectiveUserId;

  String get defaultAvatarUrl => kDefaultAvatarUrl;

  bool get hasCustomProfilePhoto {
    final avatarUrl = userService.currentUser?.avatarUrl ?? '';
    return !isDefaultAvatarUrl(avatarUrl);
  }

  Future<void> fetchAndSetUserData() => _fetchAndSetUserDataImpl();

  Future<void> pickImage({required ImageSource source}) =>
      _pickImageImpl(source: source);

  void showCropDialog() => _showCropDialogImpl();

  Future<void> updateProfileInfo() => _updateProfileInfoImpl();

  Future<void> removeProfilePhoto() => _removeProfilePhotoImpl();
}
