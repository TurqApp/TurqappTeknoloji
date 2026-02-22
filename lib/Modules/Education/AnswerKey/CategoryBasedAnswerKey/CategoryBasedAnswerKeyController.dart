import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/BookletModel.dart';

class CategoryBasedAnswerKeyController extends GetxController {
  final String sinavTuru;
  final list = <BookletModel>[].obs;
  final filteredList = <BookletModel>[].obs;
  final search = TextEditingController();
  final isLoading = true.obs;

  CategoryBasedAnswerKeyController(this.sinavTuru);

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  @override
  void onClose() {
    search.dispose();
    super.onClose();
  }

  Future<void> getData() async {
    isLoading.value = true; // Start loading
    list.clear();
    filteredList.clear();
    try {
      final snapshots = await FirebaseFirestore.instance
          .collection("Kitapciklar")
          .where("sinavTuru", isEqualTo: sinavTuru)
          .get();

      for (var doc in snapshots.docs) {
        final basimTarihi = doc.get("basimTarihi") as String;
        final baslik = doc.get("baslik") as String;
        final cover = doc.get("cover") as String;
        final dil = doc.get("dil") as String;
        final kaydet = List<String>.from(doc.get("kaydet"));
        final goruntuleme = List<String>.from(doc.get("goruntuleme"));
        final sinavTuru = doc.get("sinavTuru") as String;
        final timeStamp = doc.get("timeStamp") as num;
        final yayinEvi = doc.get("yayinEvi") as String;
        final userID = doc.get("userID") as String;

        final booklet = BookletModel(
          dil: dil,
          sinavTuru: sinavTuru,
          cover: cover,
          baslik: baslik,
          timeStamp: timeStamp,
          kaydet: kaydet,
          basimTarihi: basimTarihi,
          yayinEvi: yayinEvi,
          docID: doc.id,
          userID: userID,
          goruntuleme: goruntuleme,
        );

        list.add(booklet);
      }
      filteredList.assignAll(list);
    } catch (e) {
      print("Error fetching booklets: $e");
    } finally {
      isLoading.value = false; // End loading
    }
  }

  String normalizeText(String text) {
    const replacements = {
      'ç': 'c',
      'Ç': 'c',
      'ğ': 'g',
      'Ğ': 'g',
      'ı': 'i',
      'İ': 'i',
      'ö': 'o',
      'Ö': 'o',
      'ş': 's',
      'Ş': 's',
      'ü': 'u',
      'Ü': 'u',
    };

    return text
        .toLowerCase()
        .split('')
        .map((char) => replacements[char] ?? char)
        .join();
  }

  void filterSearchResults(String query) {
    if (query.isEmpty) {
      filteredList.assignAll(list);
    } else {
      filteredList.assignAll(
        list.where(
          (val) => normalizeText(val.baslik).contains(normalizeText(query)),
        ),
      );
    }
  }
}
