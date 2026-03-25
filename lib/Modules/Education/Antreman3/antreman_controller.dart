import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/antreman_repository.dart';
import 'package:turqappv2/Core/Repositories/question_bank_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/connectivity_helper.dart';
import 'package:turqappv2/Models/Education/question_bank_model.dart';
import 'package:turqappv2/Modules/Education/Antreman3/question_content.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'antreman_controller_actions_part.dart';
part 'antreman_controller_category_part.dart';
part 'antreman_controller_fields_part.dart';
part 'antreman_controller_models_part.dart';
part 'antreman_controller_question_actions_part.dart';
part 'antreman_controller_support_part.dart';

class AntremanController extends GetxController {
  static AntremanController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(AntremanController(), permanent: permanent);
  }

  static AntremanController? maybeFind() {
    final isRegistered = Get.isRegistered<AntremanController>();
    if (!isRegistered) return null;
    return Get.find<AntremanController>();
  }

  final QuestionBankSnapshotRepository _questionBankSnapshotRepository =
      QuestionBankSnapshotRepository.ensure();
  final AntremanRepository _antremanRepository = AntremanRepository.ensure();
  final UserRepository _userRepository = UserRepository.ensure();
  final Map<String, Map<String, List<String>>> subjects = _antremanSubjects;

  final Map<String, IconData> icons = _antremanIcons;
  final _state = _AntremanControllerState();

  final String userID = CurrentUserService.instance.effectiveUserId;
  final int batchSize = 5;

  @override
  void onInit() {
    super.onInit();
    loadMainCategory();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }
}
