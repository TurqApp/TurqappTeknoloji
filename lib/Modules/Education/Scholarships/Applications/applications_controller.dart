import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/scholarship_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/scholarship_firestore_path.dart';

class ApplicationsController extends GetxController {
  final UserRepository _userRepository = UserRepository.ensure();
  final ScholarshipRepository _scholarshipRepository =
      ScholarshipRepository.ensure();
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

      final bursList =
          await _scholarshipRepository.fetchAppliedByUserRaw(userID, limit: 50);

      // Batch user fetch instead of N+1
      final ownerIds = bursList
          .map((d) => d['userID'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      final userDocsById = ownerIds.isEmpty
          ? <String, Map<String, dynamic>>{}
          : await _userRepository.getUsersRaw(ownerIds);

      final applicationList = <Map<String, dynamic>>[];

      for (final data in bursList) {
        final bursOwnerID = data['userID'] as String? ?? '';
        final ownerData = userDocsById[bursOwnerID];
        final nickname = (ownerData?['displayName'] ??
                ownerData?['username'] ??
                ownerData?['nickname'] ??
                'Bilinmiyor')
            .toString();
        final avatarUrl = (ownerData?['avatarUrl'] ??
                ownerData?['avatarUrl'] ??
                ownerData?['avatarUrl'] ??
                ownerData?['avatarUrl'] ??
                '')
            .toString();

        applicationList.add({
          'bursID': (data['docId'] ?? '').toString(),
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
          'avatarUrl': avatarUrl,
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

      final batch = FirebaseFirestore.instance.batch();
      final docRef = ScholarshipFirestorePath.doc(bursID);
      batch.update(docRef, {
        'basvurular': FieldValue.arrayRemove([userID]),
      });
      batch.delete(docRef.collection('Basvurular').doc(userID));
      await batch.commit();

      applications.removeWhere((app) => app['bursID'] == bursID);
      Get.back();

      AppSnackbar("Başarılı", "Burs Başvurunuz Geri Alındı.");
    } catch (e) {
      AppSnackbar('Hata', 'Başvuru geri alınamadı.');
    }
  }
}
