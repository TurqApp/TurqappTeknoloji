import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavModel.dart';

class DenemeSinavlariController extends GetxController {
  var list = <SinavModel>[].obs;
  var okul = false.obs;
  var showButons = false.obs;
  var ustBar = true.obs;
  var showOkulAlert = false.obs;
  var isLoading = true.obs;
  final ScrollController scrollController = ScrollController();
  double _previousOffset = 0.0;
  final RxDouble scrollOffset = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    getData();
    scrolControlcu();
    getOkulBilgisi();
  }

  void scrolControlcu() {
    scrollController.addListener(() {
      double currentOffset = scrollController.position.pixels;

      if (currentOffset > _previousOffset) {
        if (showButons.value) showButons.value = false;
        if (ustBar.value) ustBar.value = false;
      } else if (currentOffset < _previousOffset) {
        if (showButons.value) showButons.value = false;
        if (!ustBar.value) ustBar.value = true;
      }

      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {}

      if (scrollController.position.pixels ==
          scrollController.position.minScrollExtent) {}

      _previousOffset = currentOffset;
    });
  }

  Future<void> getOkulBilgisi() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      final rozet = doc.get("rozet");
      okul.value = rozet == "Mavi";
    } catch (e) {
      AppSnackbar("Hata", "Okul bilgisi alınamadı.");
    }
  }

  Future<void> getData() async {
    isLoading.value = true;
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection("Sinavlar").get();
      list.clear();
      for (var doc in snapshot.docs) {
        final cover = doc.get("cover") as String;
        final sinavAciklama = doc.get("sinavAciklama") as String;
        final sinavAdi = doc.get("sinavAdi") as String;
        final sinavTuru = doc.get("sinavTuru") as String;
        final timeStamp = doc.get("timeStamp") as num;
        final kpssSecilenLisans = doc.get("kpssSecilenLisans") as String;
        final dersler = List<String>.from(doc['dersler'] ?? []);
        final soruSayisi = List<String>.from(doc['soruSayilari'] ?? []);
        final userID = doc.get("userID") as String;
        final taslak = doc.get("taslak") as bool;
        final public = doc.get("public") as bool;
        final bitisDk = doc.get("bitisDk") as num;
        final bitis = doc.get("bitis") as num;

        list.add(
          SinavModel(
            docID: doc.id,
            cover: cover,
            sinavTuru: sinavTuru,
            timeStamp: timeStamp,
            sinavAciklama: sinavAciklama,
            sinavAdi: sinavAdi,
            kpssSecilenLisans: kpssSecilenLisans,
            dersler: dersler,
            userID: userID,
            public: public,
            taslak: taslak,
            soruSayilari: soruSayisi,
            bitis: bitis,
            bitisDk: bitisDk,
          ),
        );
      }
    } catch (e) {
      AppSnackbar("Hata", "Veriler yüklenemedi.");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
