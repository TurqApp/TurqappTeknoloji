import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class SearchDenemeController extends GetxController {
  var list = <SinavModel>[].obs;
  var filteredList = <SinavModel>[].obs;
  var isLoading = true.obs;
  final TextEditingController searchController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    getData();
    Future.delayed(const Duration(milliseconds: 100), () {
      focusNode.requestFocus();
    });
  }

  Future<void> getData() async {
    isLoading.value = true;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("practiceExams")
          .orderBy("timeStamp", descending: true)
          .get();
      list.clear();
      for (var doc in snapshot.docs) {
        String cover = doc.get("cover");
        String sinavAciklama = doc.get("sinavAciklama");
        String sinavAdi = doc.get("sinavAdi");
        String sinavTuru = doc.get("sinavTuru");
        num timeStamp = doc.get("timeStamp");
        String kpssSecilenLisans = doc.get("kpssSecilenLisans");
        List<String> dersler = List<String>.from(doc['dersler']);
        List<String> soruSayisi = List<String>.from(doc['soruSayilari']);
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
      filteredList.assignAll(list);
    } catch (e) {
      AppSnackbar("Hata", "Veriler yüklenemedi.");
    } finally {
      isLoading.value = false;
    }
  }

  void filterSearchResults(String query) {
    if (query.isEmpty) {
      filteredList.assignAll(list);
    } else {
      filteredList.assignAll(
        list.where((test) {
          return test.sinavAciklama.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
              test.sinavTuru.toLowerCase().contains(query.toLowerCase()) ||
              test.sinavAdi.toLowerCase().contains(query.toLowerCase()) ||
              test.dersler.any(
                (ders) => ders.toLowerCase().contains(query.toLowerCase()),
              );
        }).toList(),
      );
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    focusNode.dispose();
    super.onClose();
  }
}
