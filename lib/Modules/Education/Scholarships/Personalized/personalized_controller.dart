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
  String? controllerTag;
  // Observable lists
  final RxList<IndividualScholarshipsModel> list =
      <IndividualScholarshipsModel>[].obs;
  final RxList<IndividualScholarshipsModel> vitrin =
      <IndividualScholarshipsModel>[].obs;

  // User data observables
  final RxString ikametSehir = "".obs;
  final RxString nufusSehir = "".obs;
  final RxString ikametIlce = "".obs;
  final RxString nufusIlce = "".obs;
  final RxString locationSehir = "".obs;
  final RxString schoolCity = "".obs;
  final RxString universite = "".obs;
  final RxString ortaokul = "".obs;
  final RxString lise = "".obs;
  final RxString cinsiyet = "".obs;
  final RxBool hasSchoolInfo = false.obs;
  final RxString educationLevel = "".obs;

  // docId lookup by timeStamp (since model doesn't carry docId)
  final Map<int, String> docIdByTimestamp = {};

  // UI state observables
  final RxBool showSearch = false.obs;
  final RxInt count = 0.obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isInitialLoading = true.obs;
  final RxBool isUserDataLoaded = false.obs;
  final RxBool usedFallback = false.obs;

  static const String _cacheKeyPrefix = 'personalized_scholarships_cache_v1';
  static const int _cacheLimit = 30;

  // Controllers and listeners
  final ScrollController scrollController = ScrollController();

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
