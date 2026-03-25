import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/tutoring_snapshot_repository.dart';
import 'package:turqappv2/Core/Utils/location_text_utils.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'location_based_tutoring_controller_fields_part.dart';
part 'location_based_tutoring_controller_runtime_part.dart';
part 'location_based_tutoring_controller_support_part.dart';

class LocationBasedTutoringController extends GetxController {
  static LocationBasedTutoringController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      LocationBasedTutoringController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static LocationBasedTutoringController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<LocationBasedTutoringController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<LocationBasedTutoringController>(tag: tag);
  }

  static const String _cacheKey = 'location_tutoring_cache_v1';
  final TutoringSnapshotRepository _tutoringSnapshotRepository =
      TutoringSnapshotRepository.ensure();
  final _state = _LocationBasedTutoringControllerState();

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() =>
      _LocationBasedTutoringControllerRuntimeX(this).bootstrapData();

  Future<void> fetchLocationBasedTutoring({
    bool silent = false,
  }) =>
      _LocationBasedTutoringControllerRuntimeX(this)
          .fetchLocationBasedTutoring(silent: silent);
}
