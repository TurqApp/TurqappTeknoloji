import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Utils/location_text_utils.dart';
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/Services/user_moderation_guard.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutorings/my_tutorings_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringDetail/tutoring_detail_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:flutter/services.dart' show rootBundle;

part 'create_tutoring_controller_form_part.dart';
part 'create_tutoring_controller_fields_part.dart';
part 'create_tutoring_controller_runtime_part.dart';
part 'create_tutoring_controller_submission_part.dart';
part 'create_tutoring_controller_support_part.dart';

class CreateTutoringController extends GetxController {
  static CreateTutoringController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      CreateTutoringController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static CreateTutoringController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<CreateTutoringController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<CreateTutoringController>(tag: tag);
  }

  final _state = _CreateTutoringControllerState();

  static List<String> get weekDays => _createTutoringWeekDays;
  static List<String> get timeSlots => _createTutoringTimeSlots;

  @override
  void onInit() {
    super.onInit();
    _handleRuntimeInit();
  }

  @override
  void onClose() {
    _handleRuntimeClose();
    super.onClose();
  }
}
