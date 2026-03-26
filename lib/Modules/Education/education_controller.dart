import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';
import 'package:turqappv2/Modules/Education/Antreman3/antreman_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/deneme_sinavlari_controller.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/answer_key_controller.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Market/market_controller.dart';
import 'package:turqappv2/Modules/JobFinder/job_finder_controller.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import 'package:turqappv2/Modules/Profile/Settings/settings_controller.dart';

part 'education_controller_fields_part.dart';
part 'education_controller_pasaj_part.dart';
part 'education_controller_search_part.dart';

class EducationController extends GetxController {
  static EducationController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(EducationController(), permanent: permanent);
  }

  static EducationController? maybeFind() {
    final isRegistered = Get.isRegistered<EducationController>();
    if (!isRegistered) return null;
    return Get.find<EducationController>();
  }

  final _state = _EducationControllerState();

  @override
  void onInit() {
    super.onInit();
    _initializeEducationController();
  }

  @override
  void onClose() {
    _disposeEducationController();
    super.onClose();
  }

  void resetSurfaceForTabTransition() => _performResetSurfaceForTabTransition();

  void ensureVisibleSurfaceReset() => _ensureVisibleSurfaceResetImpl();
}
