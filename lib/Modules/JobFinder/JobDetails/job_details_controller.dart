import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../JobCreator/job_creator.dart';

class JobDetailsController extends GetxController {
  /// Seçili ilan modeli
  final Rx<JobModel> model;

  /// Kaydetme durumu
  final saved = false.obs;

  /// Başvuru durumu
  final basvuruldu = false.obs;

  /// CV kontrolü
  final cvVar = false.obs;

  /// Kullanıcı bilgileri
  final nickname = ''.obs;
  final pfImage = ''.obs;
  final fullname = ''.obs;

  /// Benzer ilanlar listesi
  final RxList<JobModel> list = <JobModel>[].obs;

  JobDetailsController({required JobModel model}) : model = model.obs;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  /// Tüm asenkron init işlerini burada çağırıyoruz
  Future<void> _initialize() async {
    await cvCheck();
    await getUserData(model.value.userID);
    await checkSaved(model.value.docID);
    await checkBasvuru(model.value.docID);
    await getSimilar(model.value.meslek);
  }

  /// Kullanıcı adı, rumuz ve profil fotoğrafını getir
  Future<void> getUserData(String userID) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get();

      if (!snap.exists || snap.data() == null) return;
      final data = snap.data()!;

      fullname.value = '${data['firstName'] ?? ''} '
          '${data['lastName'] ?? ''}';
      nickname.value = data['nickname'] as String? ?? '';
      pfImage.value = data['pfImage'] as String? ?? '';
    } catch (e) {
      print('getUserData hatası: $e');
    }
  }

  /// Mevcut kullanıcının CV kaydı var mı?
  Future<void> cvCheck() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('CV')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      cvVar.value = snap.exists;
    } catch (e) {
      print('cvCheck hatası: $e');
    }
  }

  /// İlanı kaydetme durumu
  Future<void> checkSaved(String docId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final snap = await FirebaseFirestore.instance
          .collection('IsBul')
          .doc(docId)
          .collection('Saved')
          .doc(uid)
          .get();
      saved.value = snap.exists;
    } catch (e) {
      print('checkSaved hatası: $e');
      saved.value = false;
    }
  }

  /// Kaydetilen ilanı toggle et
  Future<void> toggleSave(String docId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseFirestore.instance
        .collection('IsBul')
        .doc(docId)
        .collection('Saved')
        .doc(uid);

    try {
      final snap = await ref.get();
      if (snap.exists) {
        // Sil
        await ref.delete();
        saved.value = false;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('SavedIsBul')
            .doc(docId)
            .delete();
      } else {
        // Ekle
        await ref.set({
          'timeStamp': FieldValue.serverTimestamp(),
        });
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('SavedIsBul')
            .doc(docId)
            .set({
          'timeStamp': FieldValue.serverTimestamp(),
        });
        saved.value = true;
      }
    } catch (e) {
      print('toggleSave hatası: $e');
    }
  }

  /// Benzer ilanları getir
  Future<void> getSimilar(String meslek) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('IsBul')
          .where('meslek', isEqualTo: meslek)
          .where('ended', isEqualTo: false)
          .limit(15)
          .get();

      final jobs =
          snapshot.docs.map((d) => JobModel.fromMap(d.data(), d.id)).toList();

      list.assignAll(jobs);
    } catch (e) {
      print('getSimilar hatası: $e');
    }
  }

  /// Haritalar alt sayfasını göster
  Future<void> showMapsSheet(double lat, double long) async {
    Get.bottomSheet(
      barrierColor: Colors.black.withAlpha(50),
      SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Haritalarda Aç',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'MontserratBold',
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Google Maps
              _mapTile(
                icon: 'assets/icons/googlemaps.webp',
                text: 'Google Haritalar\'da Aç',
                onTap: () async {
                  final url = Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=$lat,$long');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                  Get.back();
                },
              ),

              // iOS ise Apple Maps
              if (Platform.isIOS)
                _mapTile(
                  icon: 'assets/icons/applemaps.webp',
                  text: 'Apple Haritalar\'da Aç',
                  onTap: () async {
                    final url =
                        Uri.parse('http://maps.apple.com/?q=$lat,$long');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                    Get.back();
                  },
                ),

              // Yandex
              _mapTile(
                icon: 'assets/icons/yandexmaps.webp',
                text: 'Yandex Haritalar\'da Aç',
                onTap: () async {
                  final appUrl = Uri.parse(
                      'yandexmaps://maps.yandex.ru/?ll=$long,$lat&z=10');
                  if (await canLaunchUrl(appUrl)) {
                    await launchUrl(appUrl,
                        mode: LaunchMode.externalApplication);
                  } else {
                    final webUrl = Uri.parse(
                        'https://yandex.com/maps/?ll=$long,$lat&z=10');
                    if (await canLaunchUrl(webUrl)) {
                      await launchUrl(webUrl,
                          mode: LaunchMode.externalApplication);
                    }
                  }
                  Get.back();
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _mapTile({
    required String icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: Image.asset(icon),
            ),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(fontFamily: 'MontserratBold')),
          ],
        ),
      ),
    );
  }

  /// Mevcut kullanıcının başvuru durumu
  Future<void> checkBasvuru(String docID) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final snap = await FirebaseFirestore.instance
          .collection('IsBul')
          .doc(docID)
          .collection('Applications')
          .doc(uid)
          .get();
      basvuruldu.value = snap.exists;
    } catch (e) {
      print('checkBasvuru hatası: $e');
      basvuruldu.value = false;
    }
  }

  /// Başvuru toggle
  Future<void> toggleBasvuru(String docId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseFirestore.instance
        .collection('IsBul')
        .doc(docId)
        .collection('Applications')
        .doc(uid);

    try {
      final snap = await ref.get();
      if (snap.exists) {
        await ref.delete();
        basvuruldu.value = false;
      } else {
        await ref.set({
          'timeStamp': FieldValue.serverTimestamp(),
        });
        basvuruldu.value = true;
      }
    } catch (e) {
      print('toggleBasvuru hatası: $e');
    }
  }

  /// İlanı düzenleme sayfasına git ve güncel veri al
  Future<void> goToEdit() async {
    final result =
        await Get.to<JobModel?>(JobCreator(existingJob: model.value));
    if (result != null) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('IsBul')
            .doc(model.value.docID)
            .get();

        if (snap.exists && snap.data() != null) {
          model.value = JobModel.fromMap(snap.data()!, snap.id);
        }
      } catch (e) {
        print('goToEdit hatası: $e');
      }
    }
  }
}
