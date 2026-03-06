// 📁 lib/Services/firebase_my_store.dart
// ⚠️ DEPRECATED: Use CurrentUserService instead
// 🔄 This is a backward-compatible wrapper around CurrentUserService
// 📌 Kept for compatibility with existing code - will be removed in future versions

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/ogrenci_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

/// ⚠️ DEPRECATED - Use [CurrentUserService] instead
///
/// This class is kept for backward compatibility.
/// New code should use:
/// ```dart
/// final userService = CurrentUserService.instance;
/// final nickname = userService.currentUser?.nickname ?? '';
/// ```
@Deprecated('Use CurrentUserService instead')
class FirebaseMyStore extends GetxController {
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔗 Bridge to CurrentUserService
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  final _userService = CurrentUserService.instance;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📦 Reactive Variables (mapped from CurrentUserService)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  var userID = "".obs;
  var nickname = "".obs;
  var pfImage = "".obs;
  var firstName = "".obs;
  var lastName = "".obs;
  var email = "".obs;
  var rozet = "".obs;
  var bio = "".obs;
  var adres = "".obs;
  var phoneNumber = "".obs;
  var ban = false.obs;
  var gizliHesap = false.obs;
  var hesapOnayi = false.obs;
  var meslek = "".obs;
  var blockedUsers = <String>[].obs;
  var lastSearchList = <String>[].obs;
  var readStories = <String>[].obs;
  RxMap<String, int> readStoriesTimes = <String, int>{}.obs;
  var lastSearchedUserList = <OgrenciModel>[].obs;
  var viewSelection = 1.obs;
  var storyAvilable = false.obs;

  var totalMarket = 0.obs;
  var totalPosts = 0.obs;
  var totalLikes = 0.obs;
  var totalFollower = 0.obs;
  var totalFollowing = 0.obs;
  final scrollController = ScrollController();
  static const int _whereInChunkSize = 10;

  List<List<T>> _chunkList<T>(List<T> input, int size) {
    if (input.isEmpty) return <List<T>>[];
    final chunks = <List<T>>[];
    for (int i = 0; i < input.length; i += size) {
      final end = (i + size > input.length) ? input.length : i + size;
      chunks.add(input.sublist(i, end));
    }
    return chunks;
  }

  @override
  void onInit() {
    super.onInit();
    _syncFromUserService();
    hasStoryOwner();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔄 Sync from CurrentUserService (replaces getUserData)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Sync reactive variables from CurrentUserService
  void _syncFromUserService() {
    // Listen to user changes from CurrentUserService
    _userService.userStream.listen((user) {
      if (user == null) {
        rvesertUserData();
        return;
      }

      // Update all reactive variables
      userID.value = user.userID;
      nickname.value = user.nickname;
      pfImage.value = user.pfImage;
      firstName.value = user.firstName;
      lastName.value = user.lastName;
      email.value = user.email;
      rozet.value = user.rozet;
      bio.value = user.bio;
      adres.value = user.adres;
      phoneNumber.value = user.phoneNumber;
      ban.value = user.ban;
      gizliHesap.value = user.gizliHesap;
      hesapOnayi.value = user.hesapOnayi;
      meslek.value = user.meslekKategori;
      blockedUsers.value = user.blockedUsers;
      lastSearchList.value = user.lastSearchList;
      readStories.value = user.readStories;
      readStoriesTimes.assignAll(user.readStoriesTimes);
      viewSelection.value = user.viewSelection;

      // Statistics
      totalMarket.value = 0;
      totalFollower.value = user.counterOfFollowers;
      totalFollowing.value = user.counterOfFollowings;
      totalPosts.value = user.counterOfPosts;
      totalLikes.value = user.counterOfLikes;

      // Load last searched users
      _loadLastSearchedUsers(user.lastSearchList);
    });
  }

  /// Load last searched user models
  Future<void> _loadLastSearchedUsers(List<String> searchList) async {
    if (searchList.isEmpty) {
      lastSearchedUserList.clear();
      return;
    }

    try {
      lastSearchedUserList.clear();
      final uniqueIds =
          searchList.where((id) => id.trim().isNotEmpty).toSet().toList();
      final byId = <String, OgrenciModel>{};

      for (final chunk in _chunkList(uniqueIds, _whereInChunkSize)) {
        final snap = await FirebaseFirestore.instance
            .collection("users")
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snap.docs) {
          byId[doc.id] = OgrenciModel.fromDocument(doc);
        }
      }

      // Arama geçmişindeki sıralamayı koru.
      for (final userId in searchList) {
        final model = byId[userId];
        if (model != null) {
          lastSearchedUserList.add(model);
        }
      }
    } catch (e) {
      print('❌ Error loading last searched users: $e');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔧 Legacy Methods (kept for compatibility)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// ⚠️ DEPRECATED - Data is now automatically synced from CurrentUserService
  @Deprecated('Data is automatically synced. This method does nothing.')
  Future<void> getUserData() async {
    // No-op - CurrentUserService handles this automatically
    print('⚠️ getUserData() is deprecated. Use CurrentUserService instead.');
  }

  /// Reset user data
  void rvesertUserData() {
    userID.value = "";
    nickname.value = "";
    pfImage.value = "";
    firstName.value = "";
    lastName.value = "";
    email.value = "";
    rozet.value = "";
    bio.value = "";
    adres.value = "";
    phoneNumber.value = "";
    ban.value = false;
    gizliHesap.value = false;
    hesapOnayi.value = false;
    meslek.value = "";
    blockedUsers.clear();
    lastSearchList.clear();
    readStories.clear();
    readStoriesTimes.clear();
    viewSelection.value = 1;
    lastSearchedUserList.clear();
  }

  /// Check if user has active stories
  Future<void> hasStoryOwner() async {
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        FirebaseFirestore.instance
            .collection("stories")
            .where("userId", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .orderBy('createdDate', descending: true)
            .limit(5)
            .get()
            .then((snap) {
          final anyActive = snap.docs.any((d) {
            final data = d.data();
            return (data['deleted'] ?? false) != true;
          });
          storyAvilable.value = anyActive;
        });
      } else {
        storyAvilable.value = false;
      }
    } catch (e) {
      print("Hikaye kontrolü sırasında hata: $e");
      storyAvilable.value = false;
    }
  }
}
