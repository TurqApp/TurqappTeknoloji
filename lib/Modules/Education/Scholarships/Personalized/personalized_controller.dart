import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/scholarship_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Core/Utils/location_text_utils.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'personalized_controller_data_part.dart';
part 'personalized_controller_fields_part.dart';
part 'personalized_controller_score_part.dart';
part 'personalized_controller_runtime_part.dart';

class PersonalizedController extends GetxController {
  static String? _activeTag;

  static PersonalizedController ensure({
    required String tag,
    bool permanent = false,
  }) =>
      _ensurePersonalizedController(tag: tag, permanent: permanent);

  static PersonalizedController? maybeFind({String? tag}) =>
      _maybeFindPersonalizedController(tag: tag);

  final UserRepository _userRepository = UserRepository.ensure();
  final ScholarshipRepository _scholarshipRepository =
      ScholarshipRepository.ensure();
  final _state = _PersonalizedControllerState();

  static const String _cacheKeyPrefix = 'personalized_scholarships_cache_v1';
  static const int _cacheLimit = 30;

  @override
  void onInit() {
    super.onInit();
    _handlePersonalizedControllerInit(this);
  }

  @override
  void onClose() {
    _handlePersonalizedControllerClose(this);
    super.onClose();
  }
}
