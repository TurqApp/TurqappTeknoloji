import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Modules/SignIn/sign_in.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_cache_policy.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_read_policy.dart';
import 'package:turqappv2/Core/Repositories/user_subdoc_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Utils/account_status_utils.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/account_session_vault.dart';
import 'package:turqappv2/Services/device_session_service.dart';

import '../Models/current_user_model.dart';

part 'current_user_service_support_part.dart';
part 'current_user_service_cache_part.dart';
part 'current_user_service_access_part.dart';
part 'current_user_service_facade_part.dart';
part 'current_user_service_account_part.dart';
part 'current_user_service_auth_part.dart';
part 'current_user_service_fields_part.dart';
part 'current_user_service_lifecycle_part.dart';
part 'current_user_service_story_part.dart';
part 'current_user_service_sync_part.dart';

class CurrentUserService extends GetxController with WidgetsBindingObserver {
  static CurrentUserService? _instance;

  static CurrentUserService get instance {
    _instance ??= CurrentUserService._internal();
    return _instance!;
  }

  static CurrentUserService? maybeFind() {
    final isRegistered = Get.isRegistered<CurrentUserService>();
    if (!isRegistered) return null;
    return Get.find<CurrentUserService>();
  }

  static CurrentUserService ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(instance, permanent: permanent);
  }

  CurrentUserService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  final _state = _CurrentUserServiceState();

  String get effectiveUserId => _performEffectiveUserId();

  bool hasReadStory(String storyId) =>
      _CurrentUserServiceStoryPart(this).hasReadStory(storyId);

  int? getStoryReadTime(String userId) =>
      _CurrentUserServiceStoryPart(this).getStoryReadTime(userId);

  bool get isVerified => _CurrentUserServiceStoryPart(this).isVerified;

  @override
  void onClose() {
    _disposeLifecycleResources();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _handleLifecycleStateChange(state);
  }
}
