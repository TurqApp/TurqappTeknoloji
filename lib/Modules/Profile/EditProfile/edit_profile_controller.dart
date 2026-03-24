import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Modules/Agenda/Common/post_content_controller.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../../Core/BottomSheets/no_yes_alert.dart';

import '../../../Core/Services/optimized_nsfw_service.dart';
part 'edit_profile_controller_actions_part.dart';

class EditProfileController extends GetxController {
  static EditProfileController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      EditProfileController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static EditProfileController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<EditProfileController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<EditProfileController>(tag: tag);
  }

  final CropController cropController = CropController();
  final ImagePicker picker = ImagePicker();

  final Rx<File?> selectedImage = Rx<File?>(null);
  final Rx<Uint8List?> croppedImage = Rx<Uint8List?>(null); // preview için
  final RxBool isCropping =
      false.obs; // artık UI bağımsız, ancak geriye dönük korunuyor

  // 🎯 Using CurrentUserService for optimized user data access
  final userService = CurrentUserService.instance;
  final UserRepository _userRepository = UserRepository.ensure();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final RxString email = ''.obs;
  final RxString phoneNumber = ''.obs;
  StreamSubscription<Map<String, dynamic>?>? _userSub;

  String get _currentUid => userService.effectiveUserId;

  // Varsayılan avatar URL'si ve yardımcı durum hesaplaması
  String get defaultAvatarUrl => kDefaultAvatarUrl;

  bool get hasCustomProfilePhoto {
    final avatarUrl = userService.currentUser?.avatarUrl ?? '';
    return !isDefaultAvatarUrl(avatarUrl);
  }

  @override
  void onInit() {
    super.onInit();
    _handleLifecycleInit();
  }

  @override
  void onClose() {
    _handleLifecycleClose();
    super.onClose();
  }

  Future<void> fetchAndSetUserData() => _fetchAndSetUserDataImpl();

  Future<void> pickImage({required ImageSource source}) =>
      _pickImageImpl(source: source);

  void showCropDialog() => _showCropDialogImpl();

  Future<void> updateProfileInfo() => _updateProfileInfoImpl();

  Future<void> removeProfilePhoto() => _removeProfilePhotoImpl();

  void _handleLifecycleInit() {
    fetchAndSetUserData();
    _bindUserContactData();
    // NSFW detector OptimizedNSFWService ile lazy initialize edilir
  }

  void _handleLifecycleClose() {
    _userSub?.cancel();
    firstNameController.dispose();
    lastNameController.dispose();
  }

  void _bindUserContactData() {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    _userSub?.cancel();
    _userSub = _userRepository.watchUserRaw(uid).listen((data) {
      if (data == null) return;
      final profile = (data["profile"] is Map)
          ? Map<String, dynamic>.from(data["profile"] as Map)
          : const <String, dynamic>{};
      final rawEmail = (data["email"] ??
              profile["email"] ??
              CurrentUserService.instance.email ??
              "")
          .toString()
          .trim();
      final rawPhone = (data["phoneNumber"] ?? profile["phoneNumber"] ?? "")
          .toString()
          .trim();
      email.value = rawEmail;
      phoneNumber.value = rawPhone;
    });
  }

  Future<void> _fetchAndSetUserDataImpl() async {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    final currentUser = userService.currentUser;

    if (currentUser != null) {
      firstNameController.text = currentUser.firstName;
      lastNameController.text = currentUser.lastName;
      return;
    }

    final data = await _userRepository.getUserRaw(uid);
    if (data != null) {
      firstNameController.text = data["firstName"] ?? "";
      lastNameController.text = data["lastName"] ?? "";
    }
  }
}
