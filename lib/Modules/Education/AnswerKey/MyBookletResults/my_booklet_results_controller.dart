import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/booklet_result_model.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';

class MyBookletResultsController extends GetxController {
  final list = <BookletResultModel>[].obs;
  final optikSonuclari = <OpticalFormModel>[].obs;
  final selection = 0.obs;

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
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection("KitapcikCevaplari")
          .orderBy("timeStamp", descending: true)
          .get();

      final tempList = <BookletResultModel>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
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
      // 1) Kullanıcının yanıt verdiği tüm OptikKodlar'ın Yanitlar dokümanlarını bul
      // OptikKodlar'da Yanitlar doc ID'si = userID olduğundan, documentId filtresi kullanıyoruz
      // Ancak collectionGroup'ta documentId filtresi yok, bu yüzden path'ten filtreliyoruz
      final yanitlarSnap = await FirebaseFirestore.instance
          .collectionGroup("Yanitlar")
          .where(FieldPath.documentId, isEqualTo: currentUserUID)
          .get();

      // 2) Parent OptikKodlar doc ID'lerini topla
      final optikDocIds = <String>{};
      for (var yanitDoc in yanitlarSnap.docs) {
        final parentRef = yanitDoc.reference.parent.parent;
        if (parentRef != null && parentRef.parent.id == "optikForm") {
          optikDocIds.add(parentRef.id);
        }
      }

      if (optikDocIds.isEmpty) return;

      // 3) Parent OptikKodlar dokümanlarını batch çek
      final tempList = <OpticalFormModel>[];
      final idList = optikDocIds.toList();
      for (var i = 0; i < idList.length; i += 10) {
        final batch = idList.skip(i).take(10).toList();
        final optikSnap = await FirebaseFirestore.instance
            .collection("optikForm")
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var doc in optikSnap.docs) {
          final data = doc.data();
          tempList.add(
            OpticalFormModel(
              docID: doc.id,
              cevaplar: List<String>.from(data['cevaplar'] ?? []),
              max: data["max"] ?? 0,
              name: data["name"] ?? '',
              userID: data["userID"] ?? '',
              bitis: data["bitis"] ?? 0,
              baslangic: data["baslangic"] ?? 0,
              kisitlama: data["kisitlama"] ?? false,
            ),
          );
        }
      }

      tempList.sort((a, b) => b.baslangic.compareTo(a.baslangic));
      optikSonuclari.assignAll(tempList);
    } catch (error) {
      log("fetchOptikSonuclari error: $error");
    }
  }
}
