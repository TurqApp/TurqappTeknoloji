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
part 'cv_controller_education_part.dart';
part 'cv_controller_experience_part.dart';
part 'cv_controller_facade_part.dart';
part 'cv_controller_fields_part.dart';
part 'cv_controller_persistence_part.dart';
part 'cv_controller_profile_part.dart';

class CvController extends GetxController {
  static CvController ensure({String? tag, bool permanent = false}) =>
      _ensureCvController(tag: tag, permanent: permanent);

  static CvController? maybeFind({String? tag}) => _maybeFindCvController(
        tag: tag,
      );

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
  final _state = _CvControllerState();

  String get _currentUid => _cvCurrentUid(this);

  @override
  void onInit() {
    super.onInit();
    _handleCvControllerInit(this);
  }

  @override
  void onClose() {
    _handleCvControllerClose(this);
    super.onClose();
  }
}
