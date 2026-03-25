import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Core/Repositories/optical_form_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'optics_and_books_published_controller_runtime_part.dart';

class OpticsAndBooksPublishedController extends GetxController {
  static OpticsAndBooksPublishedController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(OpticsAndBooksPublishedController(), permanent: permanent);
  }

  static OpticsAndBooksPublishedController? maybeFind() {
    final isRegistered = Get.isRegistered<OpticsAndBooksPublishedController>();
    if (!isRegistered) return null;
    return Get.find<OpticsAndBooksPublishedController>();
  }

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

  Future<void> _bootstrapData() =>
      _OpticsAndBooksPublishedControllerRuntimeX(this)._bootstrapData();

  Future<void> loadData({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _OpticsAndBooksPublishedControllerRuntimeX(this).loadData(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  Future<void> getData({bool forceRefresh = false}) =>
      _OpticsAndBooksPublishedControllerRuntimeX(this).getData(
        forceRefresh: forceRefresh,
      );

  Future<void> getOptikler({bool forceRefresh = false}) =>
      _OpticsAndBooksPublishedControllerRuntimeX(this).getOptikler(
        forceRefresh: forceRefresh,
      );
}
