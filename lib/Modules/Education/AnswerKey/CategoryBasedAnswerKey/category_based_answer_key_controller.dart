import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';

class CategoryBasedAnswerKeyController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final String sinavTuru;
  final list = <BookletModel>[].obs;
  final filteredList = <BookletModel>[].obs;
  final search = TextEditingController();
  final isLoading = true.obs;
  final BookletRepository _bookletRepository = BookletRepository.ensure();

  CategoryBasedAnswerKeyController(this.sinavTuru);

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapData());
  }

  @override
  void onClose() {
    search.dispose();
    super.onClose();
  }

  Future<void> _bootstrapData() async {
    try {
      final cached = await _bookletRepository.fetchByExamType(
        sinavTuru,
        preferCache: true,
        cacheOnly: true,
      );
      if (cached.isNotEmpty) {
        list.assignAll(cached);
        filteredList.assignAll(cached);
        isLoading.value = false;
        if (SilentRefreshGate.shouldRefresh(
          'answer_key:type:$sinavTuru',
          minInterval: _silentRefreshInterval,
        )) {
          unawaited(getData(silent: true, forceRefresh: true));
        }
        return;
      }
    } catch (_) {}

    await getData();
  }

  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final shouldShowLoader = !silent && list.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    try {
      final items = await _bookletRepository.fetchByExamType(
        sinavTuru,
        preferCache: true,
        forceRefresh: forceRefresh,
      );
      list.assignAll(items);
      filteredList.assignAll(list);
      SilentRefreshGate.markRefreshed('answer_key:type:$sinavTuru');
    } catch (_) {
    } finally {
      if (shouldShowLoader || list.isEmpty) {
        isLoading.value = false;
      }
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
