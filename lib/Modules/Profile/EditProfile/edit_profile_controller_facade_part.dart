part of 'edit_profile_controller.dart';

EditProfileController ensureEditProfileController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindEditProfileController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    EditProfileController(),
    tag: tag,
    permanent: permanent,
  );
}

EditProfileController? maybeFindEditProfileController({String? tag}) {
  final isRegistered = Get.isRegistered<EditProfileController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<EditProfileController>(tag: tag);
}

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
