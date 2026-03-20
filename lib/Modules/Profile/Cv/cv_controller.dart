import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/cv_repository.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/Utils/phone_utils.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';
import 'package:turqappv2/Models/CVModels/school_model.dart';
import 'package:turqappv2/Modules/Profile/Cv/cv_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'cv_controller_sections_part.dart';
part 'cv_controller_persistence_part.dart';

class CvController extends GetxController {
  final CvRepository _cvRepository = CvRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  static const List<String> languageOptionKeys = <String>[
    'cv.language.english',
    'cv.language.german',
    'cv.language.french',
    'cv.language.spanish',
    'cv.language.arabic',
    'cv.language.turkish',
    'cv.language.russian',
    'cv.language.italian',
    'cv.language.korean',
  ];
  var selection = 0.obs;
  TextEditingController firstName = TextEditingController(text: "");
  TextEditingController lastName = TextEditingController(text: "");
  TextEditingController linkedin = TextEditingController(text: "");
  TextEditingController mail = TextEditingController(text: "");
  TextEditingController phoneNumber = TextEditingController(text: "");
  TextEditingController onYazi = TextEditingController(text: "");

  RxList<CvSchoolModel> okullar = <CvSchoolModel>[].obs;
  RxList<CVLanguegeModel> diler = <CVLanguegeModel>[].obs;
  RxList<CVExperinceModel> isDeneyimleri = <CVExperinceModel>[].obs;
  RxList<CVReferenceHumans> referanslar = <CVReferenceHumans>[].obs;
  RxList<String> skills = <String>[].obs;
  RxBool isSaving = false.obs;
  RxBool isUploadingPhoto = false.obs;
  RxString photoUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _seedFromCurrentUser();
    ensureDefaultPhoto();
    unawaited(_bootstrapCvData());
  }

  @override
  void onClose() {
    firstName.dispose();
    lastName.dispose();
    mail.dispose();
    phoneNumber.dispose();
    linkedin.dispose();
    onYazi.dispose();
    super.onClose();
  }

  // ── Validations ──

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

  // ── School ──

  Future<void> pickCvPhoto(BuildContext context) async {
    if (isUploadingPhoto.value) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
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
        storage: FirebaseStorage.instance,
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
    final currentAvatar = CurrentUserService.instance.avatarUrl.trim();
    if (currentAvatar.isNotEmpty) {
      photoUrl.value = currentAvatar;
    }
  }

  void _seedFromCurrentUser() {
    final currentUser = CurrentUserService.instance.currentUser;
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
  }

  Future<void> _bootstrapCvData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
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
        minInterval: _silentRefreshInterval,
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
