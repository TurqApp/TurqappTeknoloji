import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/scholarship_firestore_path.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';

class SavedItemsController extends GetxController {
  final isLoading = false.obs;
  final likedScholarships = <Map<String, dynamic>>[].obs;
  final bookmarkedScholarships = <Map<String, dynamic>>[].obs;
  final selectedTabIndex = 0.obs;
  final pageController = PageController();

  @override
  void onInit() {
    super.onInit();
    fetchSavedItems();
  }

  Future<void> fetchSavedItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar('Hata', 'Lütfen oturum açın.');
      return;
    }
    isLoading.value = true;
    try {
      await Future.wait([
        _fetchScholarships(user.uid, isLiked: true),
        _fetchScholarships(user.uid, isBookmarked: true),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchScholarships(
    String userId, {
    bool isLiked = false,
    bool isBookmarked = false,
  }) async {
    try {
      final snapshot = await ScholarshipFirestorePath.collection()
          .where(
            isLiked ? 'begeniler' : 'kaydedenler',
            arrayContains: userId,
          )
          .orderBy('timeStamp', descending: true)
          .limit(50)
          .get();

      final scholarships = <Map<String, dynamic>>[];

      // Batch fetch users
      final userIds = <String>{};
      for (var doc in snapshot.docs) {
        final userID = doc.data()['userID'] as String? ?? '';
        if (userID.isNotEmpty) userIds.add(userID);
      }

      final userDataMap = <String, Map<String, dynamic>>{};
      for (var i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();
        final usersSnap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final d in usersSnap.docs) {
          final user = d.data();
          final profileImage = (user['avatarUrl'] ??
                  user['avatarUrl'] ??
                  user['avatarUrl'] ??
                  '')
              .toString();
          final profileName = (user['displayName'] ??
                  user['username'] ??
                  user['nickname'] ??
                  '')
              .toString();
          userDataMap[d.id] = {
            'avatarUrl': profileImage,
            'nickname': profileName,
            'displayName': profileName,
            'userID': d.id,
          };
        }
      }

      for (var doc in snapshot.docs) {
        final data = doc.data();
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
            'docId': doc.id,
            'likesCount': begeniler.length,
            'bookmarksCount': kaydedenler.length,
          });
        } catch (e) {
          AppSnackbar('Hata', 'Burs verisi işlenemedi.');
        }
      }

      if (isLiked) {
        likedScholarships.value = scholarships;
      } else {
        bookmarkedScholarships.value = scholarships;
      }
    } catch (e) {
      AppSnackbar('Hata', 'Veriler yüklenemedi.');
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
      final docRef = ScholarshipFirestorePath.doc(docId);

      final doc = await docRef.get();
      if (!doc.exists) {
        AppSnackbar('Hata', 'Burs bulunamadı.');
        return;
      }

      final begeniler = List<String>.from(doc.data()?['begeniler'] ?? []);
      if (begeniler.contains(userId)) {
        begeniler.remove(userId);
      } else {
        begeniler.add(userId);
      }

      await docRef.update({'begeniler': begeniler});
      // Pull-based: listeyi yeniden çek
      await _fetchScholarships(userId, isLiked: true);
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
      final docRef = ScholarshipFirestorePath.doc(docId);

      final doc = await docRef.get();
      if (!doc.exists) {
        AppSnackbar('Hata', 'Burs bulunamadı.');
        return;
      }

      final kaydedenler = List<String>.from(doc.data()?['kaydedenler'] ?? []);
      if (kaydedenler.contains(userId)) {
        kaydedenler.remove(userId);
      } else {
        kaydedenler.add(userId);
      }

      await docRef.update({'kaydedenler': kaydedenler});
      // Pull-based: listeyi yeniden çek
      await _fetchScholarships(userId, isBookmarked: true);
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
