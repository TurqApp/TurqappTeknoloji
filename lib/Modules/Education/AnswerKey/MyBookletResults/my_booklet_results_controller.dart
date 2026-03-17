import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/optical_form_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Models/Education/booklet_result_model.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';

class MyBookletResultsController extends GetxController {
  final OpticalFormRepository _opticalFormRepository =
      OpticalFormRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final list = <BookletResultModel>[].obs;
  final optikSonuclari = <OpticalFormModel>[].obs;
  final selection = 0.obs;
  final isLoading = true.obs;
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapResults());
  }

  void setSelection(int value) {
    selection.value = value;
  }

  Future<void> _bootstrapResults() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      isLoading.value = false;
      return;
    }
    try {
      final cachedEntries = await _userSubcollectionRepository.getEntries(
        uid,
        subcollection: "KitapcikCevaplari",
        orderByField: "timeStamp",
        descending: true,
        preferCache: true,
        cacheOnly: true,
      );
      final cachedOptikler = await _opticalFormRepository.fetchAnsweredByUser(
        uid,
        preferCache: true,
        cacheOnly: true,
      );
      if (cachedEntries.isNotEmpty || cachedOptikler.isNotEmpty) {
        _assignBookletResults(cachedEntries);
        cachedOptikler.sort((a, b) => b.baslangic.compareTo(a.baslangic));
        optikSonuclari.assignAll(cachedOptikler);
        isLoading.value = false;
        if (SilentRefreshGate.shouldRefresh(
          'answer_key:results:$uid',
          minInterval: _silentRefreshInterval,
        )) {
          unawaited(refreshData(silent: true, forceRefresh: true));
        }
        return;
      }
    } catch (_) {}
    await refreshData();
  }

  Future<void> fetchBookletResults({bool forceRefresh = false}) async {
    try {
      final snapshot = await _userSubcollectionRepository.getEntries(
        FirebaseAuth.instance.currentUser!.uid,
        subcollection: "KitapcikCevaplari",
        orderByField: "timeStamp",
        descending: true,
        preferCache: true,
        forceRefresh: forceRefresh,
      );
      _assignBookletResults(snapshot);
    } catch (_) {}
  }

  /// collectionGroup query ile N+1 problemi çözüldü.
  /// Eski: tüm OptikKodlar çek → her biri için Yanitlar/{uid} oku (N+1)
  /// Yeni: collectionGroup("Yanitlar") ile uid dokümanlarını bul → parent OptikKodlar'ı batch çek
  Future<void> fetchOptikSonuclari({bool forceRefresh = false}) async {
    final currentUserUID = FirebaseAuth.instance.currentUser!.uid;

    try {
      final tempList = await _opticalFormRepository.fetchAnsweredByUser(
        currentUserUID,
        preferCache: true,
        forceRefresh: forceRefresh,
      );

      tempList.sort((a, b) => b.baslangic.compareTo(a.baslangic));
      optikSonuclari.assignAll(tempList);
    } catch (_) {}
  }

  Future<void> refreshData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final shouldShowLoader = !silent && list.isEmpty && optikSonuclari.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    await Future.wait([
      fetchBookletResults(forceRefresh: forceRefresh),
      fetchOptikSonuclari(forceRefresh: forceRefresh),
    ]);
    if (uid.isNotEmpty) {
      SilentRefreshGate.markRefreshed('answer_key:results:$uid');
    }
    if (shouldShowLoader || (list.isEmpty && optikSonuclari.isEmpty)) {
      isLoading.value = false;
    }
  }

  void _assignBookletResults(List<UserSubcollectionEntry> snapshot) {
    final tempList = <BookletResultModel>[];
    for (final doc in snapshot) {
      final data = doc.data;
      tempList.add(
        BookletResultModel(
          cevaplar: List.from(data["cevaplar"] ?? []),
          docID: doc.id,
          baslik: data["baslik"] ?? '',
          timeStamp: data["timeStamp"] ?? 0,
          yanlis: data["yanlis"] ?? 0,
          dogru: data["dogru"] ?? 0,
          bos: data["bos"] ?? 0,
          kitapcikID: data["kitapcikID"] ?? '',
          puan: data["puan"] ?? 0,
          dogruCevaplar: List.from(data["dogruCevaplar"] ?? []),
        ),
      );
    }
    list.assignAll(tempList);
  }
}
