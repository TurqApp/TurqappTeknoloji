import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

class ScholarshipProvidersController extends GetxController {
  final isLoading = true.obs;
  final providers = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchProviders();
  }

  Future<void> fetchProviders() async {
    try {
      isLoading.value = true;

      // Sadece son 200 burstan unique provider'ları çek
      final bursSnapshot = await FirebaseFirestore.instance
          .collection('catalog')
          .doc('education')
          .collection('scholarships')
          .orderBy('timeStamp', descending: true)
          .limit(200)
          .get();

      final seenUserIDs = <String>{};
      for (var bursDoc in bursSnapshot.docs) {
        final userID = bursDoc.data()['userID'] as String?;
        if (userID != null && userID.isNotEmpty) {
          seenUserIDs.add(userID);
        }
      }

      if (seenUserIDs.isEmpty) {
        providers.clear();
        return;
      }

      // Batch user fetch (max 30 per whereIn)
      final providerList = <Map<String, dynamic>>[];
      final userIdsList = seenUserIDs.toList();
      for (var i = 0; i < userIdsList.length; i += 30) {
        final end =
            (i + 30) > userIdsList.length ? userIdsList.length : (i + 30);
        final batchIds = userIdsList.sublist(i, end);
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();
        for (final userDoc in snap.docs) {
          providerList.add({
            'userID': userDoc.id,
            'pfImage': userDoc.data()['pfImage'] as String? ?? '',
            'nickname': userDoc.data()['nickname'] as String? ?? 'Bilinmeyen',
            'rozet': userDoc.data()['rozet'] as String? ?? '',
          });
        }
      }

      providers.assignAll(providerList);
    } catch (e) {
      AppSnackbar('Hata', 'Burs verenler yüklenemedi.');
    } finally {
      isLoading.value = false;
    }
  }
}
