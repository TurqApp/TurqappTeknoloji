import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/answer_key_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyContent/answer_key_content_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'answer_key_controller_data_part.dart';
part 'answer_key_controller_fields_part.dart';
part 'answer_key_controller_facade_part.dart';
part 'answer_key_controller_search_part.dart';
part 'answer_key_controller_ui_part.dart';

class AnswerKeyController extends GetxController {
  static AnswerKeyController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(AnswerKeyController(), permanent: permanent);
  }

  static AnswerKeyController? maybeFind() {
    final isRegistered = Get.isRegistered<AnswerKeyController>();
    if (!isRegistered) return null;
    return Get.find<AnswerKeyController>();
  }

  static const String _listingSelectionPrefKeyPrefix =
      'pasaj_answer_key_listing_selection';
  final _AnswerKeyControllerState _state = _AnswerKeyControllerState();
  static const int _pageSize = 30;

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }

  @override
  void onClose() {
    _handleControllerClose();
    super.onClose();
  }
}
