import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
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
part 'cv_controller_profile_part.dart';

class CvController extends GetxController {
  static CvController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      CvController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static CvController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<CvController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<CvController>(tag: tag);
  }

  final CvRepository _cvRepository = CvRepository.ensure();
  final CurrentUserService _userService = CurrentUserService.instance;
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

  String get _currentUid => _userService.effectiveUserId;

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
}
