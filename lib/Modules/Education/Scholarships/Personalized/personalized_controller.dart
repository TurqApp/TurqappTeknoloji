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

class PersonalizedController extends GetxController {
  static String? _activeTag;

  static PersonalizedController ensure({
    required String tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) {
      _activeTag = tag;
      return existing;
    }
    final created = Get.put(
      PersonalizedController(),
      tag: tag,
      permanent: permanent,
    );
    created.controllerTag = tag;
    _activeTag = tag;
    return created;
  }

  static PersonalizedController? maybeFind({String? tag}) {
    final resolvedTag = (tag ?? _activeTag)?.trim();
    if (resolvedTag != null && resolvedTag.isNotEmpty) {
      final isRegistered =
          Get.isRegistered<PersonalizedController>(tag: resolvedTag);
      if (!isRegistered) return null;
      return Get.find<PersonalizedController>(tag: resolvedTag);
    }
    final isRegistered = Get.isRegistered<PersonalizedController>();
    if (!isRegistered) return null;
    return Get.find<PersonalizedController>();
  }

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
    _initializeData();
    _setupScrollListener();
  }

  String get _cacheKey {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return '$_cacheKeyPrefix:guest';
    return '$_cacheKeyPrefix:$uid';
  }

  @override
  void onClose() {
    if (_activeTag == controllerTag) {
      _activeTag = null;
    }
    scrollController.dispose();
    super.onClose();
  }
}
