import 'dart:developer';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SavedPracticeExams/saved_practice_exams_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'deneme_sinavlari_controller_data_part.dart';
part 'deneme_sinavlari_controller_facade_part.dart';
part 'deneme_sinavlari_controller_fields_part.dart';
part 'deneme_sinavlari_controller_runtime_part.dart';

class DenemeSinavlariController extends GetxController {
  static DenemeSinavlariController ensure({
    bool permanent = false,
  }) =>
      _ensureDenemeSinavlariController(permanent: permanent);

  static DenemeSinavlariController? maybeFind() =>
      _maybeFindDenemeSinavlariController();

  static const String _listingSelectionPrefKeyPrefix =
      'pasaj_practice_exam_listing_selection';
  final _state = _DenemeSinavlariControllerState();
  static const int _pageSize = ReadBudgetRegistry.practiceExamHomeInitialLimit;

  bool get hasActiveSearch => _hasActivePracticeExamSearch(this);

  @override
  void onInit() {
    super.onInit();
    _handleDenemeSinavlariInit(this);
  }

  @override
  void onClose() {
    _handleDenemeSinavlariClose(this);
    super.onClose();
  }
}
