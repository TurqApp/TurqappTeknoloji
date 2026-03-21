import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';

class CategoryBasedAnswerKeyController extends GetxController {
  static CategoryBasedAnswerKeyController ensure(
    String sinavTuru, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      CategoryBasedAnswerKeyController(sinavTuru),
      tag: tag,
      permanent: permanent,
    );
  }

  static CategoryBasedAnswerKeyController? maybeFind({String? tag}) {
    if (!Get.isRegistered<CategoryBasedAnswerKeyController>(tag: tag)) {
      return null;
    }
    return Get.find<CategoryBasedAnswerKeyController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final String sinavTuru;
  final list = <BookletModel>[].obs;
  final filteredList = <BookletModel>[].obs;
  final search = TextEditingController();
  final isLoading = true.obs;
  final BookletRepository _bookletRepository = BookletRepository.ensure();

  CategoryBasedAnswerKeyController(this.sinavTuru);

  bool _sameBookletEntries(
    List<BookletModel> current,
    List<BookletModel> next,
  ) {
    final currentKeys = current
        .map(
          (item) => [
            item.docID,
            item.baslik,
            item.sinavTuru,
            item.yayinEvi,
            item.basimTarihi,
            item.dil,
            item.timeStamp,
            item.viewCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (item) => [
            item.docID,
            item.baslik,
            item.sinavTuru,
            item.yayinEvi,
            item.basimTarihi,
            item.dil,
            item.timeStamp,
            item.viewCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

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
        if (!_sameBookletEntries(list, cached)) {
          list.assignAll(cached);
        }
        if (!_sameBookletEntries(filteredList, cached)) {
          filteredList.assignAll(cached);
        }
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
      if (!_sameBookletEntries(list, items)) {
        list.assignAll(items);
      }
      if (!_sameBookletEntries(filteredList, list)) {
        filteredList.assignAll(list);
      }
      SilentRefreshGate.markRefreshed('answer_key:type:$sinavTuru');
    } catch (_) {
    } finally {
      if (shouldShowLoader || list.isEmpty) {
        isLoading.value = false;
      }
    }
  }

  String normalizeText(String text) {
    return normalizeSearchText(text);
  }

  void filterSearchResults(String query) {
    if (query.isEmpty) {
      if (!_sameBookletEntries(filteredList, list)) {
        filteredList.assignAll(list);
      }
    } else {
      final next = list
          .where(
            (val) => normalizeText(val.baslik).contains(normalizeText(query)),
          )
          .toList(growable: false);
      if (!_sameBookletEntries(filteredList, next)) {
        filteredList.assignAll(next);
      }
    }
  }
}
