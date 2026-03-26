import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Repositories/scholarship_repository.dart';
import 'package:turqappv2/Core/Repositories/scholarship_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';
// Corporate ScholarshipsModel no longer used; only IndividualScholarshipsModel remains
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/DormitoryInfo/dormitory_info_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/EducationInfo/education_info_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/FamilyInfo/family_info_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/PersonelInfo/personel_info_view.dart';

part 'scholarships_controller_data_part.dart';
part 'scholarships_controller_actions_part.dart';
part 'scholarships_controller_fields_part.dart';
part 'scholarships_controller_models_part.dart';
part 'scholarships_controller_runtime_part.dart';
part 'scholarships_controller_support_part.dart';

class ScholarshipsController extends GetxController {
  static const String _listingSelectionPrefKeyPrefix =
      'scholarship_listing_selection';

  static ScholarshipsController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ScholarshipsController(), permanent: permanent);
  }

  static ScholarshipsController? maybeFind() {
    final isRegistered = Get.isRegistered<ScholarshipsController>();
    if (!isRegistered) return null;
    return Get.find<ScholarshipsController>();
  }

  final _state = _ScholarshipsControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}
