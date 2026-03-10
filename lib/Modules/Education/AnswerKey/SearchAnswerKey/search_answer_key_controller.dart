import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletPreview/booklet_preview.dart';

class SearchAnswerKeyController extends GetxController {
  final searchController = TextEditingController();
  final list = <BookletModel>[].obs;
  final filteredList = <BookletModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    getData();
    searchController.addListener(() {
      onSearchChanged(searchController.text);
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> getData() async {
    try {
      final snapshots =
          await FirebaseFirestore.instance.collection("books").get();
      final newList = <BookletModel>[];
      for (var doc in snapshots.docs) {
        newList.add(BookletModel.fromMap(doc.data(), doc.id));
      }
      list.assignAll(newList);
      filteredList.assignAll(newList);
      log("Çekilen kitapçık sayısı: ${newList.length}");
      log(
        "Kitapçık başlıkları: ${newList.map((e) => '${e.docID}: ${e.baslik}').toList()}",
      );
    } catch (e) {
      log("Veri çekme hatası: $e");
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

  void onSearchChanged(String value) {
    if (value.isEmpty) {
      filteredList.assignAll(list);
    } else {
      filteredList.assignAll(
        list.where(
          (val) =>
              normalizeText(val.baslik).contains(normalizeText(value)) ||
              normalizeText(val.yayinEvi).contains(normalizeText(value)),
        ),
      );
    }
  }

  void navigateToPreview(BookletModel model) {
    Get.to(() => BookletPreview(model: model));
  }
}
