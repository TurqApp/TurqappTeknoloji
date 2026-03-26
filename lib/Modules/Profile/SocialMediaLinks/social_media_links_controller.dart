import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/social_media_model.dart';
import 'package:turqappv2/Core/Repositories/social_media_links_repository.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Modules/Profile/SocialMediaLinks/social_media_branding.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'add_social_media_bottom_sheet.dart';

part 'social_media_links_controller_fields_part.dart';
part 'social_media_links_controller_facade_part.dart';
part 'social_media_links_controller_runtime_part.dart';

class SocialMediaController extends GetxController {
  static SocialMediaController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(SocialMediaController());
  }

  static SocialMediaController? maybeFind() {
    final isRegistered = Get.isRegistered<SocialMediaController>();
    if (!isRegistered) return null;
    return Get.find<SocialMediaController>();
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _SocialMediaControllerState();

  @override
  void onInit() {
    super.onInit();
    _SocialMediaControllerRuntimeX(this).handleOnInit();
  }
}
