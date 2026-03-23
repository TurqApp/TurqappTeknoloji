import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../../Models/ogrenci_model.dart';

part 'blocked_users_controller_data_part.dart';
part 'blocked_users_controller_actions_part.dart';

class BlockedUsersController extends GetxController {
  static BlockedUsersController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      BlockedUsersController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static BlockedUsersController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<BlockedUsersController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<BlockedUsersController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  RxList<String> blockedUsers = <String>[].obs;
  RxList<OgrenciModel> blockedUserDetails = <OgrenciModel>[].obs;
  RxBool isLoading = true.obs;
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final UserSubcollectionRepository _subcollectionRepository =
      UserSubcollectionRepository.ensure();

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapBlockedUsers());
  }
}
