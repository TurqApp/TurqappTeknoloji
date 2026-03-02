import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class SinavSonuclarimController extends GetxController {
  var list = <SinavModel>[].obs;
  var ustBar = true.obs;
  var isLoading = true.obs;
  final ScrollController scrollController = ScrollController();
  double _previousOffset = 0.0;

  @override
  void onInit() {
    super.onInit();
    scrolControlcu();
    findAndGetSinavlar();
  }

  void scrolControlcu() {
    scrollController.addListener(() {
      double currentOffset = scrollController.position.pixels;

      if (currentOffset > _previousOffset) {
        if (ustBar.value) ustBar.value = false;
      } else if (currentOffset < _previousOffset) {
        if (!ustBar.value) ustBar.value = true;
      }

      _previousOffset = currentOffset;
    });
  }

  /// collectionGroup query ile N+1 problemi çözüldü.
  /// Eski yöntem: tüm practiceExams çek → her biri için Yanitlar sorgula (N+1)
  /// Yeni yöntem: collectionGroup("Yanitlar") ile kullanıcının yanıtlarını bul → parent doc'ları batch çek
  Future<void> findAndGetSinavlar() async {
    isLoading.value = true;
    try {
      final currentUserID = FirebaseAuth.instance.currentUser!.uid;

      // 1) Kullanıcının yanıtladığı tüm Yanitlar dokümanlarını tek sorguda çek
      final yanitlarSnap = await FirebaseFirestore.instance
          .collectionGroup("Yanitlar")
          .where("userID", isEqualTo: currentUserID)
          .get();

      // 2) Parent practiceExam doc ID'lerini topla (sadece practiceExams altındakileri)
      final examDocIds = <String>{};
      for (var yanitDoc in yanitlarSnap.docs) {
        final parentRef = yanitDoc.reference.parent.parent;
        if (parentRef != null && parentRef.parent.id == "practiceExams") {
          examDocIds.add(parentRef.id);
        }
      }

      if (examDocIds.isEmpty) {
        list.clear();
        return;
      }

      // 3) Parent practiceExam dokümanlarını batch çek (10'lu gruplar - whereIn limiti)
      final tempList = <SinavModel>[];
      final idList = examDocIds.toList();
      for (var i = 0; i < idList.length; i += 10) {
        final batch = idList.skip(i).take(10).toList();
        final examSnap = await FirebaseFirestore.instance
            .collection("practiceExams")
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var doc in examSnap.docs) {
          final data = doc.data();
          tempList.add(
            SinavModel(
              docID: doc.id,
              cover: (data["cover"] ?? '') as String,
              sinavTuru: (data["sinavTuru"] ?? '') as String,
              timeStamp: (data["timeStamp"] ?? 0) as num,
              sinavAciklama: (data["sinavAciklama"] ?? '') as String,
              sinavAdi: (data["sinavAdi"] ?? '') as String,
              kpssSecilenLisans: (data["kpssSecilenLisans"] ?? '') as String,
              dersler: List<String>.from(data['dersler'] ?? []),
              userID: (data["userID"] ?? '') as String,
              public: (data["public"] ?? false) as bool,
              taslak: (data["taslak"] ?? false) as bool,
              soruSayilari: List<String>.from(data['soruSayilari'] ?? []),
              bitis: (data["bitis"] ?? 0) as num,
              bitisDk: (data["bitisDk"] ?? 0) as num,
            ),
          );
        }
      }

      tempList.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
      list.assignAll(tempList);
    } catch (e) {
      log("SinavSonuclarimController error: $e");
      AppSnackbar("Hata", "Sınav sonuçları yüklenemedi.");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
