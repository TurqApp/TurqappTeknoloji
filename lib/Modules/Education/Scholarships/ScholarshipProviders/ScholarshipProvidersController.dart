import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';

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

      final bursSnapshot =
          await FirebaseFirestore.instance.collection('BireyselBurslar').get();

      final providerList = <Map<String, dynamic>>[];
      final seenUserIDs = <String>{};

      for (var bursDoc in bursSnapshot.docs) {
        final userID = bursDoc.data()['userID'] as String?;

        if (userID != null && !seenUserIDs.contains(userID)) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userID)
              .get();

          if (userDoc.exists) {
            providerList.add({
              'userID': userID,
              'pfImage': userDoc.data()?['pfImage'] as String? ?? '',
              'nickname':
                  userDoc.data()?['nickname'] as String? ?? 'Bilinmeyen',
              'rozet': userDoc.data()?['rozet'] as String? ?? '',
            });
            seenUserIDs.add(userID);
          }
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
