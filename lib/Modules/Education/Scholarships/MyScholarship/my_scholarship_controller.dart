import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/scholarship_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_constants.dart';

class MyScholarshipController extends GetxController {
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final ScholarshipRepository _scholarshipRepository =
      ScholarshipRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  var isLoading = true.obs;
  final myScholarships = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapMyScholarships());
  }

  Future<void> _bootstrapMyScholarships() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar('common.error'.tr, 'scholarship.login_required'.tr);
      isLoading.value = false;
      return;
    }

    try {
      final cachedRaw = await _scholarshipRepository.fetchMyScholarshipsRaw(
        user.uid,
        limit: 50,
        cacheOnly: true,
      );
      if (cachedRaw.isNotEmpty) {
        myScholarships.assignAll(
          await _buildScholarshipCards(cachedRaw, userCacheOnly: true),
        );
        isLoading.value = false;
        if (SilentRefreshGate.shouldRefresh(
          'scholarships:mine:${user.uid}',
          minInterval: _silentRefreshInterval,
        )) {
          unawaited(fetchMyScholarships(silent: true, forceRefresh: true));
        }
        return;
      }
    } catch (_) {}

    await fetchMyScholarships();
  }

  Future<void> fetchMyScholarships({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar('common.error'.tr, 'scholarship.login_required'.tr);
      isLoading.value = false;
      return;
    }

    final shouldShowLoader = !silent && myScholarships.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    try {
      final rawScholarships =
          await _scholarshipRepository.fetchMyScholarshipsRaw(
        user.uid,
        limit: 50,
        forceRefresh: forceRefresh,
      );
      myScholarships.value = await _buildScholarshipCards(rawScholarships);
      SilentRefreshGate.markRefreshed('scholarships:mine:${user.uid}');
    } catch (e) {
      AppSnackbar('common.error'.tr, 'common.data_load_failed'.tr);
    } finally {
      if (shouldShowLoader || myScholarships.isEmpty) {
        isLoading.value = false;
      }
    }
  }

  Future<List<Map<String, dynamic>>> _buildScholarshipCards(
    List<Map<String, dynamic>> rawScholarships, {
    bool userCacheOnly = false,
  }) async {
    final scholarships = <Map<String, dynamic>>[];
    final userIds = <String>{};
    for (final data in rawScholarships) {
      final userID = data['userID'] as String? ?? '';
      if (userID.isNotEmpty) userIds.add(userID);
    }

    final userDataMap = <String, Map<String, dynamic>>{};
    final fetchedUsers = userIds.isEmpty
        ? <String, UserSummary>{}
        : await _userSummaryResolver.resolveMany(
            userIds.toList(),
            preferCache: true,
            cacheOnly: userCacheOnly,
          );
    for (final entry in fetchedUsers.entries) {
      final user = entry.value;
      userDataMap[entry.key] = {
        'avatarUrl': user.avatarUrl,
        'nickname': user.nickname,
        'displayName': user.preferredName,
        'userID': entry.key,
      };
    }

    for (final data in rawScholarships) {
      try {
        final userID = data['userID'] as String? ?? '';
        final userData = userDataMap[userID] ??
            {
              'avatarUrl': '',
              'nickname': '',
              'displayName': '',
              'userID': userID
            };

        scholarships.add({
          'model': IndividualScholarshipsModel.fromJson(data),
          'type': kIndividualScholarshipType,
          'userData': userData,
          'docId': (data['docId'] ?? '').toString(),
        });
      } catch (_) {
        AppSnackbar('common.error'.tr, 'common.item_process_failed'.tr);
      }
    }
    return scholarships;
  }
}
