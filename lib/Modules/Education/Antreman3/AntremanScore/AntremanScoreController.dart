import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/FirebaseMyStore.dart';

class AntremanScoreController extends GetxController {
  final RxList<Map<String, dynamic>> leaderboard = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final userPoint = 0.obs;
  final user = Get.find<FirebaseMyStore>();
  final now = DateTime.now();
  final monthName = RxString(monthNames[DateTime.now().month]);

  static const monthNames = [
    '',
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık'
  ];

  @override
  void onInit() {
    super.onInit();
    fetchLeaderboard();
    getUserAntPoint();
  }

  Future<void> fetchLeaderboard() async {
    try {
      isLoading.value = true;
      List<Map<String, dynamic>> tempLeaderboard = [];
      int rank = 1;
      const int limit = 100;
      DocumentSnapshot? lastDocument;

      while (tempLeaderboard.length < limit) {
        Query<Map<String, dynamic>> query = FirebaseFirestore.instance
            .collection('users')
            .orderBy('antPoint', descending: true)
            .limit(limit);

        if (lastDocument != null) {
          query = query.startAfterDocument(lastDocument);
        }

        final snapshot = await query.get();

        if (snapshot.docs.isEmpty) break;

        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data();
          String nickname = data['nickname'] ?? '';
          if (nickname.length > 4 &&
              !tempLeaderboard.any((user) => user['userID'] == doc.id)) {
            data['rank'] = rank++;
            data['userID'] = doc.id;
            tempLeaderboard.add(data);
          }
        }

        if (snapshot.docs.isNotEmpty) {
          lastDocument = snapshot.docs.last;
        } else {
          break;
        }

        if (tempLeaderboard.length >= limit) break;
      }

      leaderboard.assignAll(tempLeaderboard.take(limit).toList());
    } catch (e) {
      log("Lider tablosu çekilirken hata: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getUserAntPoint() async {
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get()
        .then((doc) {
      userPoint.value = doc.get("antPoint") ?? 0;
    });
  }
}
