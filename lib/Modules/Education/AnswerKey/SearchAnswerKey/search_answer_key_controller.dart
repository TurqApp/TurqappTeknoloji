import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletPreview/booklet_preview.dart';

class SearchAnswerKeyController extends GetxController {
  final searchController = TextEditingController();
  final list = <BookletModel>[].obs;
  final filteredList = <BookletModel>[].obs;
  final BookletRepository _bookletRepository = BookletRepository.ensure();

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
      final newList = await _bookletRepository.fetchAll(preferCache: true);
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
