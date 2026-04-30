part of 'cv_controller.dart';

extension CvControllerProfilePart on CvController {
  bool validateEmail(String email) {
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    return regex.hasMatch(email);
  }

  bool validatePhone(String phone) {
    final digits = phoneDigitsOnly(phone);
    return digits.length == 10 || digits.length == 11;
  }

  bool validateLinkedIn(String url) {
    return isLinkedInProfileUrl(url);
  }

  bool _validateYear(String year) {
    if (isPresentCvYear(year) || year.isEmpty) return true;
    final y = int.tryParse(year);
    if (y == null) return false;
    return y >= 1950 && y <= DateTime.now().year + 6;
  }

  String localizedYearLabel(String year) {
    final normalized = year.trim();
    if (normalized.isEmpty) return normalized;
    return isPresentCvYear(normalized) ? 'cv.present'.tr : normalized;
  }

  Future<void> pickCvPhoto(BuildContext context) async {
    if (isUploadingPhoto.value) return;
    final uid = _currentUid;
    if (uid.isEmpty) {
      AppSnackbar('common.error'.tr, 'cv.not_signed_in'.tr);
      return;
    }

    final File? file = await AppImagePickerService.pickSingleImage(context);
    if (file == null) return;

    isUploadingPhoto.value = true;
    try {
      final nsfwResult = await OptimizedNSFWService.checkImage(file);
      if (nsfwResult.isNSFW) {
        AppSnackbar(
          'common.error'.tr,
          'cv.photo_inappropriate'.tr,
        );
        return;
      }

      final url = await WebpUploadService.uploadFileAsWebp(
        file: file,
        storagePathWithoutExt: 'users/$uid/cv/profile_photo',
        quality: 88,
        maxWidth: 800,
        maxHeight: 800,
      );
      photoUrl.value = url;
    } catch (_) {
      AppSnackbar('common.error'.tr, 'cv.photo_upload_failed'.tr);
    } finally {
      isUploadingPhoto.value = false;
    }
  }

  String normalizeLanguageValue(String value) {
    return normalizeCvLanguageValue(value);
  }

  String localizedLanguage(String value) {
    final normalized = normalizeLanguageValue(value);
    return normalized.startsWith('cv.language.') ? normalized.tr : value;
  }

  void ensureDefaultPhoto() {
    if (photoUrl.value.trim().isNotEmpty) return;
    final currentAvatar = _userService.avatarUrl.trim();
    if (currentAvatar.isNotEmpty) {
      photoUrl.value = currentAvatar;
    }
  }

  void _seedFromCurrentUser() {
    final currentUser = _userService.currentUser;
    if (currentUser == null) return;

    if (firstName.text.trim().isEmpty) {
      firstName.text = currentUser.firstName.trim();
    }
    if (lastName.text.trim().isEmpty) {
      lastName.text = currentUser.lastName.trim();
    }
    if (mail.text.trim().isEmpty) {
      mail.text = currentUser.email.trim();
    }
    if (phoneNumber.text.trim().isEmpty) {
      phoneNumber.text = currentUser.phoneNumber.trim();
    }
    if (onYazi.text.trim().isEmpty) {
      onYazi.text = currentUser.bio.trim();
    }
  }

  Future<void> _bootstrapCvData() async {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    final cached = await _cvRepository.getCv(
      uid,
      preferCache: true,
      cacheOnly: true,
    );
    if (cached != null) {
      _applyCvData(cached);
      ensureDefaultPhoto();
      if (SilentRefreshGate.shouldRefresh(
        'profile:cv:$uid',
        minInterval: _cvSilentRefreshInterval,
      )) {
        unawaited(loadDataFromFirestore(forceRefresh: true));
      }
      return;
    }
    await loadDataFromFirestore();
  }

  void _applyCvData(Map<String, dynamic> data) {
    firstName.text = data["firstName"] ?? firstName.text;
    lastName.text = data["lastName"] ?? lastName.text;
    linkedin.text = data["linkedin"] ?? linkedin.text;
    mail.text = data["mail"] ?? data["email"] ?? mail.text;
    phoneNumber.text = data["phone"] ?? data["phoneNumber"] ?? phoneNumber.text;
    onYazi.text = data["about"] ?? onYazi.text;
    photoUrl.value = (data["photoUrl"] ?? photoUrl.value).toString().trim();

    okullar.value = (data["okullar"] as List<dynamic>? ?? [])
        .map((e) => CvSchoolModel.fromMap(e))
        .toList(growable: false);
    diler.value = (data["diller"] as List<dynamic>? ?? [])
        .map((e) => CVLanguegeModel.fromMap(e))
        .toList(growable: false);
    isDeneyimleri.value = (data["deneyim"] as List<dynamic>? ?? [])
        .map((e) => CVExperinceModel.fromMap(e))
        .toList(growable: false);
    referanslar.value = (data["referans"] as List<dynamic>? ?? [])
        .map((e) => CVReferenceHumans.fromMap(e))
        .toList(growable: false);
    skills.value = (data["skills"] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(growable: false);
  }
}
