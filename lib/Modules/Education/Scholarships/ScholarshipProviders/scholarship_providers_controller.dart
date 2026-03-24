import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/scholarship_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';

class ScholarshipProvidersController extends GetxController {
  static ScholarshipProvidersController ensure({
    required String tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ScholarshipProvidersController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static ScholarshipProvidersController? maybeFind({required String tag}) {
    final isRegistered =
        Get.isRegistered<ScholarshipProvidersController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ScholarshipProvidersController>(tag: tag);
  }

  final UserRepository _userRepository = UserRepository.ensure();
  final ScholarshipRepository _scholarshipRepository =
      ScholarshipRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final isLoading = true.obs;
  final providers = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapProviders());
  }

  Future<void> _bootstrapProviders() async {
    final cached = await _loadProviders(cacheOnly: true);
    if (cached.isNotEmpty) {
      providers.assignAll(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'scholarships:providers',
        minInterval: _silentRefreshInterval,
      )) {
        unawaited(fetchProviders(silent: true, forceRefresh: true));
      }
      return;
    }
    await fetchProviders();
  }

  Future<void> fetchProviders({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    try {
      if (!silent || providers.isEmpty) {
        isLoading.value = true;
      }
      final providerList = await _loadProviders(
        cacheOnly: false,
        forceRefresh: forceRefresh,
      );
      providers.assignAll(providerList);
      SilentRefreshGate.markRefreshed('scholarships:providers');
    } catch (e) {
      AppSnackbar('common.error'.tr, 'scholarship.providers_load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> _loadProviders({
    bool cacheOnly = false,
    bool forceRefresh = false,
  }) async {
    final scholarships = await _scholarshipRepository.fetchLatestRaw(
      limit: ReadBudgetRegistry.scholarshipProviderSeedLimit,
      preferCache: !forceRefresh,
      forceRefresh: forceRefresh,
      cacheOnly: cacheOnly,
    );

    final seenUserIDs = <String>{};
    for (final bursDoc in scholarships) {
      final userID = bursDoc['userID'] as String?;
      if (userID != null && userID.isNotEmpty) {
        seenUserIDs.add(userID);
      }
    }

    if (seenUserIDs.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final providerList = <Map<String, dynamic>>[];
    final userIdsList = seenUserIDs.toList();
    for (var i = 0; i < userIdsList.length; i += 30) {
      final end = (i + 30) > userIdsList.length ? userIdsList.length : (i + 30);
      final batchIds = userIdsList.sublist(i, end);
      final users = await _userRepository.getUsers(
        batchIds,
        cacheOnly: cacheOnly,
      );
      for (final entry in users.entries) {
        final userDocId = entry.key;
        final user = entry.value.toMap();
        final profileImage = (user['avatarUrl'] ?? '').toString();
        final profileName = (user['displayName'] ??
                user['username'] ??
                user['nickname'] ??
                'common.unknown_user'.tr)
            .toString();
        providerList.add({
          'userID': userDocId,
          'avatarUrl': profileImage,
          'nickname': profileName,
          'displayName': profileName,
          'rozet': user['rozet'] as String? ?? '',
        });
      }
    }
    return providerList;
  }
}
