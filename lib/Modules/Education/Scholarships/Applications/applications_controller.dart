import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

class ApplicationsController extends GetxController {
  final isLoading = true.obs;
  final applications = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchApplications();
  }

  Future<void> fetchApplications() async {
    try {
      isLoading.value = true;
      final userID = FirebaseAuth.instance.currentUser?.uid;
      if (userID == null) {
        AppSnackbar('Hata', 'Kullanıcı oturumu açık değil.');
        isLoading.value = false;
        return;
      }

      final bursSnapshot = await FirebaseFirestore.instance
          .collection('BireyselBurslar')
          .where('basvurular', arrayContains: userID)
          .get();

      final applicationList = <Map<String, dynamic>>[];

      for (var bursDoc in bursSnapshot.docs) {
        final data = bursDoc.data();
        final bursOwnerID = data['userID'] as String? ?? '';

        String nickname = 'Bilinmiyor';
        String pfImage = '';
        if (bursOwnerID.isNotEmpty) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(bursOwnerID)
                .get();
            if (userDoc.exists) {
              final userData = userDoc.data();
              nickname = userData?['nickname'] as String? ?? 'Bilinmiyor';
              pfImage = userData?['pfImage'] as String? ?? '';
            }
          } catch (e) {
            print('Error fetching user data: $e');
          }
        }

        applicationList.add({
          'bursID': bursDoc.id,
          'title': data['baslik'] as String? ?? 'Burs Başlığı',
          'img': data['img'] as String? ?? '',
          'desc': data['aciklama'] as String? ?? 'Açıklama yok',
          'basvuruKosullari':
              data['basvuruKosullari'] as String? ?? 'Belirtilmemiş',
          'belgeler': data['belgeler'] as List<dynamic>? ?? [],
          'aylar': data['aylar'] as List<dynamic>? ?? [],
          'baslangicTarihi': data['baslangicTarihi'] as String? ?? '',
          'bitisTarihi': data['bitisTarihi'] as String? ?? '',
          'egitimKitlesi': data['egitimKitlesi'] as String? ?? '',
          'altEgitimKitlesi': data['altEgitimKitlesi'] as List<dynamic>? ?? [],
          'universiteler': data['universiteler'] as List<dynamic>? ?? [],
          'mukerrerDurumu': data['mukerrerDurumu'] as String? ?? '',
          'geriOdemeli': data['geriOdemeli'] as String? ?? '',
          'basvuruURL': data['basvuruURL'] as String? ?? '',
          'basvuruYapilacakYer': data['basvuruYapilacakYer'] as String? ?? '',
          'timeStamp': data['timeStamp'] as num? ?? 0,
          'tutar': data['tutar'] as String? ?? '',
          'ogrenciSayisi': data['ogrenciSayisi'] as String? ?? '',
          'sehirler': data['sehirler'] as List<dynamic>? ?? [],
          'hedefKitle': data['hedefKitle'] as String? ?? '',
          'nickname': nickname,
          'userID': bursOwnerID,
          'pfImage': pfImage,
        });
      }

      applications.assignAll(applicationList);
    } catch (e) {
      AppSnackbar('Hata', 'Başvurular yüklenemedi.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> withdrawApplication(String bursID) async {
    try {
      final userID = FirebaseAuth.instance.currentUser?.uid;
      if (userID == null) {
        AppSnackbar('Hata', 'Kullanıcı oturumu açık değil.');
        return;
      }

      await FirebaseFirestore.instance
          .collection('BireyselBurslar')
          .doc(bursID)
          .update({
        'basvurular': FieldValue.arrayRemove([userID]),
      });

      applications.removeWhere((app) => app['bursID'] == bursID);
      Get.back();

      AppSnackbar("Başarılı", "Burs Başvurunuz Geri Alındı.");
    } catch (e) {
      AppSnackbar('Hata', 'Başvuru geri alınamadı.');
    }
  }
}
