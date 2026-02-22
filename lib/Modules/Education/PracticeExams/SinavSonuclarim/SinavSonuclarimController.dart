import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavModel.dart';

class SinavSonuclarimController extends GetxController {
  var list = <SinavModel>[].obs;
  var ustBar = true.obs;
  var isLoading = true.obs;
  final ScrollController scrollController = ScrollController();
  double _previousOffset = 0.0;

  @override
  void onInit() {
    super.onInit();
    scrolControlcu();
    findAndGetSinavlar();
  }

  void scrolControlcu() {
    scrollController.addListener(() {
      double currentOffset = scrollController.position.pixels;

      if (currentOffset > _previousOffset) {
        print("Aşağıya kaydırılıyor");
        if (ustBar.value) {
          ustBar.value = false;
        }
      } else if (currentOffset < _previousOffset) {
        print("Yukarıya kaydırılıyor");
        if (!ustBar.value) {
          ustBar.value = true;
        }
      }

      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        print("Alt kısma ulaşıldı");
      }

      if (scrollController.position.pixels ==
          scrollController.position.minScrollExtent) {
        print("Üst kısma ulaşıldı");
      }

      _previousOffset = currentOffset;
    });
  }

  Future<void> findAndGetSinavlar() async {
    isLoading.value = true;
    try {
      final currentUserID = FirebaseAuth.instance.currentUser!.uid;
      final testlerQuerySnapshot =
          await FirebaseFirestore.instance.collection("Sinavlar").get();

      list.clear();
      for (var doc in testlerQuerySnapshot.docs) {
        final yanitlarQuerySnapshot = await doc.reference
            .collection("Yanitlar")
            .where("userID", isEqualTo: currentUserID)
            .get();

        if (yanitlarQuerySnapshot.docs.isNotEmpty) {
          String cover = doc.get("cover");
          String sinavAciklama = doc.get("sinavAciklama");
          String sinavAdi = doc.get("sinavAdi");
          String sinavTuru = doc.get("sinavTuru");
          num timeStamp = doc.get("timeStamp");
          String kpssSecilenLisans = doc.get("kpssSecilenLisans");
          List<String> dersler = List<String>.from(doc['dersler']);
          List<String> soruSayisi =
              List<String>.from(doc['soruSayilari']);
          String userID = doc.get("userID");
          bool taslak = doc.get("taslak");
          bool public = doc.get("public");
          num bitisDk = doc.get("bitisDk");
          num bitis = doc.get("bitis");

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
      }
    } catch (e) {
      AppSnackbar("Hata", "Sınav sonuçları yüklenemedi.");
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
