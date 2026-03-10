import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';

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
          .collection("books")
          .where("sinavTuru", isEqualTo: sinavTuru)
          .get();

      for (var doc in snapshots.docs) {
        list.add(BookletModel.fromMap(doc.data(), doc.id));
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
