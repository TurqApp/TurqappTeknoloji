import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/optical_form_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Models/Education/booklet_result_model.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';

class MyBookletResultsController extends GetxController {
  final OpticalFormRepository _opticalFormRepository =
      OpticalFormRepository.ensure();
  final list = <BookletResultModel>[].obs;
  final optikSonuclari = <OpticalFormModel>[].obs;
  final selection = 0.obs;
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    fetchBookletResults();
    fetchOptikSonuclari();
  }

  void setSelection(int value) {
    selection.value = value;
  }

  Future<void> fetchBookletResults() async {
    try {
      final snapshot = await _userSubcollectionRepository.getEntries(
        FirebaseAuth.instance.currentUser!.uid,
        subcollection: "KitapcikCevaplari",
        orderByField: "timeStamp",
        descending: true,
        preferCache: true,
      );

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
    } catch (e) {
      log("fetchBookletResults error: $e");
    }
  }

  /// collectionGroup query ile N+1 problemi çözüldü.
  /// Eski: tüm OptikKodlar çek → her biri için Yanitlar/{uid} oku (N+1)
  /// Yeni: collectionGroup("Yanitlar") ile uid dokümanlarını bul → parent OptikKodlar'ı batch çek
  Future<void> fetchOptikSonuclari() async {
    optikSonuclari.clear();
    final currentUserUID = FirebaseAuth.instance.currentUser!.uid;

    try {
      final tempList = await _opticalFormRepository.fetchAnsweredByUser(
        currentUserUID,
        preferCache: true,
      );

      tempList.sort((a, b) => b.baslangic.compareTo(a.baslangic));
      optikSonuclari.assignAll(tempList);
    } catch (error) {
      log("fetchOptikSonuclari error: $error");
    }
  }
}
