import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/scholarship_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_constants.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class SavedItemsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final isLoading = false.obs;
  final likedScholarships = <Map<String, dynamic>>[].obs;
  final bookmarkedScholarships = <Map<String, dynamic>>[].obs;
  final selectedTabIndex = 0.obs;
  final pageController = PageController();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final ScholarshipRepository _scholarshipRepository =
      ScholarshipRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapSavedItems());
  }

  Future<void> _bootstrapSavedItems() async {
    final userId = CurrentUserService.instance.userId;
    if (userId.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.login_required'.tr);
      return;
    }

    try {
      final results = await Future.wait<List<Map<String, dynamic>>>([
        _fetchScholarships(
          userId,
          isLiked: true,
          cacheOnly: true,
          assignResult: false,
        ),
        _fetchScholarships(
          userId,
          isBookmarked: true,
          cacheOnly: true,
          assignResult: false,
        ),
      ]);
      final liked = results[0];
      final bookmarked = results[1];
      if (liked.isNotEmpty || bookmarked.isNotEmpty) {
        likedScholarships.assignAll(liked);
        bookmarkedScholarships.assignAll(bookmarked);
        isLoading.value = false;
        if (SilentRefreshGate.shouldRefresh(
          'scholarships:saved:$userId',
          minInterval: _silentRefreshInterval,
        )) {
          unawaited(fetchSavedItems(silent: true, forceRefresh: true));
        }
        return;
      }
    } catch (_) {}

    await fetchSavedItems();
  }

  Future<void> fetchSavedItems({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final userId = CurrentUserService.instance.userId;
    if (userId.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.login_required'.tr);
      return;
    }
    final shouldShowLoader =
        !silent && likedScholarships.isEmpty && bookmarkedScholarships.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    try {
      await Future.wait([
        _fetchScholarships(
          userId,
          isLiked: true,
          forceRefresh: forceRefresh,
        ),
        _fetchScholarships(
          userId,
          isBookmarked: true,
          forceRefresh: forceRefresh,
        ),
      ]);
      SilentRefreshGate.markRefreshed('scholarships:saved:$userId');
    } finally {
      if (shouldShowLoader ||
          (likedScholarships.isEmpty && bookmarkedScholarships.isEmpty)) {
        isLoading.value = false;
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchScholarships(
    String userId, {
    bool isLiked = false,
    bool isBookmarked = false,
    bool forceRefresh = false,
    bool cacheOnly = false,
    bool assignResult = true,
  }) async {
    try {
      final docs = await _scholarshipRepository.fetchByArrayMembershipRaw(
        isLiked ? 'begeniler' : 'kaydedenler',
        userId,
        limit: 50,
        forceRefresh: forceRefresh,
        cacheOnly: cacheOnly,
      );

      final scholarships = <Map<String, dynamic>>[];

      // Batch fetch users
      final userIds = <String>{};
      for (final data in docs) {
        final userID = data['userID'] as String? ?? '';
        if (userID.isNotEmpty) userIds.add(userID);
      }

      final userDataMap = <String, Map<String, dynamic>>{};
      final users = await _userSummaryResolver.resolveMany(
        userIds.toList(growable: false),
        preferCache: true,
        cacheOnly: cacheOnly,
      );
      for (final entry in users.entries) {
        final user = entry.value;
        userDataMap[entry.key] = {
          'avatarUrl': user.avatarUrl,
          'nickname': user.nickname,
          'displayName': user.preferredName,
          'userID': entry.key,
        };
      }

      for (final data in docs) {
        final begeniler = data['begeniler'] as List<dynamic>? ?? [];
        final kaydedenler = data['kaydedenler'] as List<dynamic>? ?? [];

        try {
          final userID = data['userID'] as String? ?? '';
          final userData = userDataMap[userID] ??
              {'avatarUrl': '', 'nickname': '', 'userID': userID};

          scholarships.add({
            'model': IndividualScholarshipsModel.fromJson(data),
            'type': kIndividualScholarshipType,
            'userData': userData,
            'docId': (data['docId'] ?? '').toString(),
            'likesCount': begeniler.length,
            'bookmarksCount': kaydedenler.length,
          });
        } catch (e) {
          AppSnackbar('common.error'.tr, 'common.item_process_failed'.tr);
        }
      }

      if (assignResult) {
        if (isLiked) {
          likedScholarships.value = scholarships;
        } else {
          bookmarkedScholarships.value = scholarships;
        }
      }
      return scholarships;
    } catch (e) {
      AppSnackbar('common.error'.tr, 'common.data_load_failed'.tr);
      return const <Map<String, dynamic>>[];
    }
  }

  Future<void> toggleLike(String docId, String type) async {
    final userId = CurrentUserService.instance.userId;
    if (userId.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.login_required'.tr);
      return;
    }

    try {
      await _scholarshipRepository.toggleLike(
        docId,
        userId: userId,
      );
      await _fetchScholarships(userId, isLiked: true, forceRefresh: true);
    } catch (e) {
      AppSnackbar('common.error'.tr, 'scholarship.like_failed'.tr);
    }
  }

  Future<void> toggleBookmark(String docId, String type) async {
    final userId = CurrentUserService.instance.userId;
    if (userId.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.login_required'.tr);
      return;
    }

    try {
      await _scholarshipRepository.toggleBookmark(
        docId,
        userId: userId,
      );
      await _fetchScholarships(
        userId,
        isBookmarked: true,
        forceRefresh: true,
      );
    } catch (e) {
      AppSnackbar('common.error'.tr, 'scholarship.bookmark_failed'.tr);
    }
  }

  void onTabChanged(int index) {
    selectedTabIndex.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeInOut,
    );
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
