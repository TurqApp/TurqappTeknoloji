import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Core/Repositories/optical_form_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class OpticsAndBooksPublishedController extends GetxController {
  final BookletRepository _bookletRepository = BookletRepository.ensure();
  final OpticalFormRepository _opticalFormRepository =
      OpticalFormRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final list = <BookletModel>[].obs;
  final optikler = <OpticalFormModel>[].obs;
  final selection = 0.obs;
  final isLoading = true.obs;
  final RxDouble scrollOffset = 0.0.obs;
  int _lastOpenRefreshAt = 0;

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

  bool _sameOpticalEntries(
    List<OpticalFormModel> current,
    List<OpticalFormModel> next,
  ) {
    final currentKeys = current
        .map(
          (item) => [
            item.docID,
            item.name,
            item.userID,
            item.cevaplar.length,
            item.max,
            item.baslangic,
            item.bitis,
            item.kisitlama,
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (item) => [
            item.docID,
            item.name,
            item.userID,
            item.cevaplar.length,
            item.max,
            item.baslangic,
            item.bitis,
            item.kisitlama,
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

  void setSelection(int value) {
    selection.value = value;
  }

  void refreshOnOpen() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (isLoading.value) return;
    if (now - _lastOpenRefreshAt < 800) return;
    _lastOpenRefreshAt = now;
    loadData(forceRefresh: true);
  }

  Future<void> _bootstrapData() async {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty) {
      isLoading.value = false;
      return;
    }
    try {
      final cachedBooks = await _bookletRepository.fetchByOwner(
        uid,
        preferCache: true,
        cacheOnly: true,
      );
      final cachedOptikler = await _opticalFormRepository.fetchByOwner(
        uid,
        preferCache: true,
        cacheOnly: true,
      );
      if (cachedBooks.isNotEmpty || cachedOptikler.isNotEmpty) {
        cachedBooks.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
        cachedOptikler.sort((a, b) => b.docID.compareTo(a.docID));
        if (!_sameBookletEntries(list, cachedBooks)) {
          list.assignAll(cachedBooks);
        }
        if (!_sameOpticalEntries(optikler, cachedOptikler)) {
          optikler.assignAll(cachedOptikler);
        }
        isLoading.value = false;
        if (SilentRefreshGate.shouldRefresh(
          'answer_key:published:$uid',
          minInterval: _silentRefreshInterval,
        )) {
          unawaited(loadData(silent: true, forceRefresh: true));
        }
        return;
      }
    } catch (_) {}
    await loadData();
  }

  Future<void> loadData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final uid = CurrentUserService.instance.userId;
    final shouldShowLoader = !silent && list.isEmpty && optikler.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    await Future.wait([
      getData(forceRefresh: forceRefresh),
      getOptikler(forceRefresh: forceRefresh),
    ]);
    if (uid.isNotEmpty) {
      SilentRefreshGate.markRefreshed('answer_key:published:$uid');
    }
    if (shouldShowLoader || (list.isEmpty && optikler.isEmpty)) {
      isLoading.value = false;
    }
  }

  Future<void> getData({bool forceRefresh = false}) async {
    final tempList = await _bookletRepository.fetchByOwner(
      CurrentUserService.instance.userId,
      preferCache: true,
      forceRefresh: forceRefresh,
    );
    tempList.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    if (!_sameBookletEntries(list, tempList)) {
      list.assignAll(tempList);
    }
  }

  Future<void> getOptikler({bool forceRefresh = false}) async {
    final tempList = await _opticalFormRepository.fetchByOwner(
      CurrentUserService.instance.userId,
      preferCache: true,
      forceRefresh: forceRefresh,
    );
    tempList.sort((a, b) => b.docID.compareTo(a.docID));
    if (!_sameOpticalEntries(optikler, tempList)) {
      optikler.assignAll(tempList);
    }
  }
}
