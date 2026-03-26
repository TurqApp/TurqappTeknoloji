import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'saved_practice_exams_controller_fields_part.dart';
part 'saved_practice_exams_controller_facade_part.dart';
part 'saved_practice_exams_controller_runtime_part.dart';

class SavedPracticeExamsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _SavedPracticeExamsControllerState();

  @override
  void onInit() {
    super.onInit();
    _SavedPracticeExamsControllerRuntimeX(this).handleOnInit();
  }
}
