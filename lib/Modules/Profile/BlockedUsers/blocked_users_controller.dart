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

  Future<void> _bootstrapBlockedUsers() async {
    final hasLocal = await _hydrateBlockedUsersFromCache();
    if (hasLocal) {
      isLoading.value = false;
      final uid = _currentUid;
      if (uid.isNotEmpty &&
          SilentRefreshGate.shouldRefresh(
            'blocked_users:$uid',
            minInterval: BlockedUsersController._silentRefreshInterval,
          )) {
        unawaited(fetchBlockedUserIDsAndDetails(
          silent: true,
          forceRefresh: true,
        ));
      }
      return;
    }
    await fetchBlockedUserIDsAndDetails();
  }

  Future<bool> _hydrateBlockedUsersFromCache() async {
    final uid = _currentUid;
    final entries = await _subcollectionRepository.getEntries(
      uid,
      subcollection: 'blockedUsers',
      preferCache: true,
      cacheOnly: true,
    );
    if (entries.isNotEmpty) {
      blockedUsers.value = entries.map((d) => d.id).toList();
      await fetchBlockedUserDetails(cacheOnly: true);
      return blockedUserDetails.isNotEmpty;
    }

    final data = await _userRepository.getUserRaw(uid, cacheOnly: true);
    if (data != null && data.containsKey("blockedUsers")) {
      blockedUsers.value = List<String>.from(data["blockedUsers"] ?? const []);
      await fetchBlockedUserDetails(cacheOnly: true);
      return blockedUsers.isNotEmpty;
    }
    return false;
  }

  Future<void> fetchBlockedUserIDsAndDetails({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent) {
      isLoading.value = true;
    }
    try {
      final uid = _currentUid;
      final entries = await _subcollectionRepository.getEntries(
        uid,
        subcollection: 'blockedUsers',
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      if (entries.isNotEmpty) {
        blockedUsers.value = entries.map((d) => d.id).toList();
        await fetchBlockedUserDetails(
          cacheOnly: false,
          preferCache: !forceRefresh,
        );
        SilentRefreshGate.markRefreshed('blocked_users:$uid');
        return;
      }

      final data = await _userRepository.getUserRaw(
        uid,
        preferCache: !forceRefresh,
        forceServer: forceRefresh,
      );
      if (data != null && data.containsKey("blockedUsers")) {
        blockedUsers.value =
            List<String>.from(data["blockedUsers"] ?? const <String>[]);
        await fetchBlockedUserDetails(
          cacheOnly: false,
          preferCache: !forceRefresh,
        );
        SilentRefreshGate.markRefreshed('blocked_users:$uid');
        return;
      }
      blockedUsers.clear();
      blockedUserDetails.clear();
      SilentRefreshGate.markRefreshed('blocked_users:$uid');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchBlockedUserDetails({
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    if (blockedUsers.isEmpty) {
      blockedUserDetails.clear();
      return;
    }

    final profiles = await _userSummaryResolver.resolveMany(
      blockedUsers.toList(),
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    final nextDetails = <OgrenciModel>[];
    for (final userID in blockedUsers) {
      final data = profiles[userID];
      if (data != null) {
        nextDetails.add(
          OgrenciModel(
            userID: userID,
            firstName: data.displayName,
            lastName: '',
            avatarUrl: data.avatarUrl,
            nickname: data.preferredName,
          ),
        );
      }
    }
    blockedUserDetails.assignAll(nextDetails);
  }
}
