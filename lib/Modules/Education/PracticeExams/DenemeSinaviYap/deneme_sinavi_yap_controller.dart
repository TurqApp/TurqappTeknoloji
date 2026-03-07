import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/ders_ve_sonuclar_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/soru_model.dart';

class DenemeSinaviYapController extends GetxController
    with WidgetsBindingObserver {
  var fullName = "".obs;
  var list = <SoruModel>[].obs;
  var selectedAnswers = <String>[].obs;
  var dersSonuclari = <DersVeSonuclar>[].obs;
  var selection = 0.obs;
  var isConnected = true.obs;
  var hataCount = 0.obs;
  var isLoading = true.obs;
  var isInitialized = false.obs;

  final SinavModel model;
  final Function sinaviBitir;
  final Function showGecersizAlert;
  final bool uyariAtla;

  DenemeSinaviYapController({
    required this.model,
    required this.sinaviBitir,
    required this.showGecersizAlert,
    required this.uyariAtla,
  });

  @override
  void onInit() {
    super.onInit();
    selection.value = uyariAtla ? 0 : 1;
    fetchUserData();
    getSorular();
    checkInternetConnection();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      print("Uygulama arka plana atıldı.");
    } else if (state == AppLifecycleState.resumed) {
      print("Uygulama ön plana geldi.");
      if (hataCount.value == 1) {
        sinaviGecersizSay();
      } else {
        AppSnackbar(
          "Uyarı !",
          "Uygulamayı arka plana almanız gibi kritik durumlarda, sınavınız geçersiz sayılacaktır. Lütfen dikkatli olun ve kurallara uygun hareket edin.",
        );
      }
      hataCount.value += 1;
      selectedAnswers.value = List<String>.filled(list.length, "");
    } else if (state == AppLifecycleState.detached) {
      sinaviGecersizSay();
    }
  }

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      String firstName = doc.get("firstName");
      String lastName = doc.get("lastName");
      fullName.value = "$firstName $lastName";
    } catch (error) {
      AppSnackbar("Hata", "Kullanıcı bilgileri yüklenemedi.");
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }

  Future<void> getSorular() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection("practiceExams")
          .doc(model.docID)
          .collection("Sorular")
          .get();

      List<SoruModel> tempList = [];
      for (var doc in snap.docs) {
        String ders = doc.get("ders");
        String dogruCevap = doc.get("dogruCevap");
        num id = doc.get("id");
        String konu = doc.get("konu");
        String soru = doc.get("soru");

        tempList.add(
          SoruModel(
            id: id.toInt(),
            soru: soru,
            ders: ders,
            konu: konu,
            dogruCevap: dogruCevap,
            docID: doc.id,
          ),
        );
      }

      list.value = tempList;
      selectedAnswers.value = List<String>.filled(tempList.length, "");
    } catch (error) {
      AppSnackbar("Hata", "Sorular yüklenemedi.");
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }

  void checkInternetConnection() {
    Connectivity().onConnectivityChanged.listen((results) {
      isConnected.value = results.any((r) => r != ConnectivityResult.none);
      print(
        isConnected.value
            ? "İnternet bağlantısı var."
            : "İnternet bağlantısı yok.",
      );
    });
  }

  void sinaviGecersizSay() {
    FirebaseFirestore.instance
        .collection("practiceExams")
        .doc(model.docID)
        .set({
      "gecersizSayilanlar": FieldValue.arrayUnion([
        FirebaseAuth.instance.currentUser!.uid,
      ]),
    }, SetOptions(merge: true));
    Get.back();
    showGecersizAlert();
  }

  Future<void> setData() async {
    final docID = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      await FirebaseFirestore.instance
          .collection("practiceExams")
          .doc(model.docID)
          .collection("Yanitlar")
          .doc(docID)
          .set({
        "yanitlar": selectedAnswers,
        "userID": FirebaseAuth.instance.currentUser!.uid,
        "timeStamp": DateTime.now().millisecondsSinceEpoch.toInt(),
      });
      SetOptions(merge: true);

      List<DersVeSonuclar> yeniSonuclar = [];
      for (var ders in model.dersler) {
        int dogru = 0;
        int yanlis = 0;
        int bos = 0;

        for (var soru in list.where((soru) => soru.ders == ders)) {
          final index = list.indexOf(soru);
          final selected = selectedAnswers[index];

          if (selected == "" || selected.isEmpty) {
            bos++;
          } else if (selected == soru.dogruCevap) {
            dogru++;
          } else {
            yanlis++;
          }
        }

        yeniSonuclar.add(
          DersVeSonuclar(ders: ders, dogru: dogru, yanlis: yanlis, bos: bos),
        );
      }

      dersSonuclari.value = yeniSonuclar;

      for (var sonuc in dersSonuclari) {
        await FirebaseFirestore.instance
            .collection("practiceExams")
            .doc(model.docID)
            .collection("Yanitlar")
            .doc(docID)
            .collection(sonuc.ders)
            .doc(docID)
            .set({
          "bos": sonuc.bos,
          "yanlis": sonuc.yanlis,
          "dogru": sonuc.dogru,
          "ders": sonuc.ders,
          "net": sonuc.dogru - (0.25 * sonuc.yanlis),
        });
        SetOptions(merge: true);
      }

      Get.back();
      sinaviBitir();
    } catch (error) {
      AppSnackbar("Hata", "Yanıtlar kaydedilemedi.");
    }
  }

  Future<void> refreshData() async {
    await fetchUserData();
    await getSorular();
  }
}
