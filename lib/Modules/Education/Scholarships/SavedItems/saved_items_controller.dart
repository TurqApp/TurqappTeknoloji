import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/scholarship_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';

class SavedItemsController extends GetxController {
  final isLoading = false.obs;
  final likedScholarships = <Map<String, dynamic>>[].obs;
  final bookmarkedScholarships = <Map<String, dynamic>>[].obs;
  final selectedTabIndex = 0.obs;
  final pageController = PageController();
  final UserRepository _userRepository = UserRepository.ensure();
  final ScholarshipRepository _scholarshipRepository =
      ScholarshipRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapSavedItems());
  }

  Future<void> _bootstrapSavedItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar('Hata', 'Lütfen oturum açın.');
      return;
    }

    try {
      final results = await Future.wait<List<Map<String, dynamic>>>([
        _fetchScholarships(
          user.uid,
          isLiked: true,
          cacheOnly: true,
          assignResult: false,
        ),
        _fetchScholarships(
          user.uid,
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
        await fetchSavedItems(silent: true, forceRefresh: true);
        return;
      }
    } catch (_) {}

    await fetchSavedItems();
  }

  Future<void> fetchSavedItems({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar('Hata', 'Lütfen oturum açın.');
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
          user.uid,
          isLiked: true,
          forceRefresh: forceRefresh,
        ),
        _fetchScholarships(
          user.uid,
          isBookmarked: true,
          forceRefresh: forceRefresh,
        ),
      ]);
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
      final users = await _userRepository.getUsersRaw(
        userIds.toList(growable: false),
        preferCache: true,
        cacheOnly: cacheOnly,
      );
      for (final entry in users.entries) {
        final user = entry.value;
        final profileImage = (user['avatarUrl'] ?? '').toString();
        final profileName = (user['displayName'] ??
                user['username'] ??
                user['nickname'] ??
                '')
            .toString();
        userDataMap[entry.key] = {
          'avatarUrl': profileImage,
          'nickname': profileName,
          'displayName': profileName,
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
            'type': 'bireysel',
            'userData': userData,
            'docId': (data['docId'] ?? '').toString(),
            'likesCount': begeniler.length,
            'bookmarksCount': kaydedenler.length,
          });
        } catch (e) {
          AppSnackbar('Hata', 'Burs verisi işlenemedi.');
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
      AppSnackbar('Hata', 'Veriler yüklenemedi.');
      return const <Map<String, dynamic>>[];
    }
  }

  Future<void> toggleLike(String docId, String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar('Hata', 'Lütfen oturum açın.');
      return;
    }
    final userId = user.uid;

    try {
      await _scholarshipRepository.toggleLike(
        docId,
        userId: userId,
      );
      await _fetchScholarships(userId, isLiked: true, forceRefresh: true);
    } catch (e) {
      AppSnackbar('Hata', 'Beğeni işlemi başarısız.');
    }
  }

  Future<void> toggleBookmark(String docId, String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar('Hata', 'Lütfen oturum açın.');
      return;
    }
    final userId = user.uid;

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
      AppSnackbar('Hata', 'Kaydetme işlemi başarısız.');
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
