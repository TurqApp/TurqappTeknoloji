import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class SavedOpticalFormsController extends GetxController {
  static SavedOpticalFormsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SavedOpticalFormsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static SavedOpticalFormsController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<SavedOpticalFormsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SavedOpticalFormsController>(tag: tag);
  }

  final BookletRepository _bookletRepository = BookletRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final list = <BookletModel>[].obs;
  final isLoading = false.obs;
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();

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

  Future<void> _bootstrapData() async {
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isEmpty) {
        isLoading.value = false;
        return;
      }
      final savedEntries = await _userSubcollectionRepository.getEntries(
        uid,
        subcollection: "books",
        orderByField: "createdAt",
        descending: true,
        preferCache: true,
        cacheOnly: true,
      );
      if (savedEntries.isNotEmpty) {
        final books = await _bookletRepository.fetchByIds(
          savedEntries.map((e) => e.id).toList(growable: false),
          preferCache: true,
          cacheOnly: true,
        );
        if (books.isNotEmpty) {
          if (!_sameBookletEntries(list, books)) {
            list.assignAll(books);
          }
          isLoading.value = false;
          if (SilentRefreshGate.shouldRefresh(
            'answer_key:saved_books:$uid',
            minInterval: _silentRefreshInterval,
          )) {
            unawaited(getData(silent: true, forceRefresh: true));
          }
          return;
        }
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
      final uid = CurrentUserService.instance.effectiveUserId;
      final savedEntries = await _userSubcollectionRepository.getEntries(
        uid,
        subcollection: "books",
        orderByField: "createdAt",
        descending: true,
        preferCache: true,
        forceRefresh: forceRefresh,
      );
      final books = await _bookletRepository.fetchByIds(
        savedEntries.map((e) => e.id).toList(growable: false),
        preferCache: true,
      );
      if (!_sameBookletEntries(list, books)) {
        list.assignAll(books);
      }
      SilentRefreshGate.markRefreshed('answer_key:saved_books:$uid');
    } catch (_) {
    } finally {
      if (shouldShowLoader || list.isEmpty) {
        isLoading.value = false;
      }
    }
  }
}
