import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';

class MyScholarshipController extends GetxController {
  var isLoading = true.obs;
  final myScholarships = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyScholarships();
  }

  Future<void> fetchMyScholarships() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar('Hata', 'Lütfen oturum açın.');
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('scholarships')
          .where('userID', isEqualTo: user.uid)
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
          userDataMap[d.id] = {
            'pfImage': d.data()['pfImage'] as String? ?? '',
            'nickname': d.data()['nickname'] as String? ?? '',
            'userID': d.id,
          };
        }
      }

      for (var doc in snapshot.docs) {
        final data = doc.data();
        try {
          final userID = data['userID'] as String? ?? '';
          final userData = userDataMap[userID] ??
              {'pfImage': '', 'nickname': '', 'userID': userID};

          scholarships.add({
            'model': IndividualScholarshipsModel.fromJson(data),
            'type': 'bireysel',
            'userData': userData,
            'docId': doc.id,
          });
        } catch (e) {
          AppSnackbar('Hata', 'Burs verisi işlenemedi.');
        }
      }

      myScholarships.value = scholarships;
    } catch (e) {
      AppSnackbar('Hata', 'Veriler yüklenemedi.');
    } finally {
      isLoading.value = false;
    }
  }
}
