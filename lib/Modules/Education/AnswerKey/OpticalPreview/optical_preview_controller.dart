import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';

class OpticalPreviewController extends GetxController
    with WidgetsBindingObserver {
  final OpticalFormModel model;
  final Function? onUpdate;
  final Function gecersizSay;

  final cevaplar = <String>[].obs;
  final isConnected = true.obs;
  final selection = 0.obs;
  final hataCount = 0.obs;
  final fullName = TextEditingController();
  final ogrenciNo = TextEditingController();

  OpticalPreviewController(this.model, this.onUpdate, this.gecersizSay) {
    _initialize();
  }

  void _initialize() {
    cevaplar.value = List.generate(model.cevaplar.length, (index) => "");
    kullaniciyiSinavGirdiKaydet();
    checkInternetConnection();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    fullName.dispose();
    ogrenciNo.dispose();
    super.onClose();
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      print("Uygulama arka plana atıldı.");
    } else if (state == AppLifecycleState.resumed) {
      print("Uygulama ön plana geldi.");
      hataCount.value++;
      cevaplar.value = List.generate(model.cevaplar.length, (index) => "");

      if (hataCount.value == 1) {
        showAlertDialog(
          "Son Uyarı !",
          "Son hatırlatmamızdır! Uygulamayı arka plana almanız gibi kritik durumlarda, sınavınız geçersiz sayılacaktır. Bu defalık sınavınıza devam edebilirsiniz, ancak tüm cevaplarınız sıfırlanmıştır. Lütfen dikkatli olun ve kurallara uygun hareket edin.",
        );
      } else {
        sinaviGecersizSay();
      }
    } else if (state == AppLifecycleState.detached) {
      sinaviGecersizSay();
    }
  }

  void sinaviGecersizSay() {
    if (!model.kisitlama) {
      final gecersizList = List.filled(model.cevaplar.length, "");
      FirebaseFirestore.instance
          .collection("OptikKodlar")
          .doc(model.docID)
          .collection("Yanitlar")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
            "timeStamp": DateTime.now().millisecondsSinceEpoch,
            "cevaplar": gecersizList,
          });
      Get.back();
      gecersizSay();
    }
  }

  void setData() {
    FirebaseFirestore.instance
        .collection("OptikKodlar")
        .doc(model.docID)
        .collection("Yanitlar")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
          "timeStamp": DateTime.now().millisecondsSinceEpoch,
          "cevaplar": cevaplar,
          "ogrenciNo": ogrenciNo.text,
          "fullName": fullName.text,
        });
    Get.back();
  }

  void kullaniciyiSinavGirdiKaydet() {
    FirebaseFirestore.instance
        .collection("OptikKodlar")
        .doc(model.docID)
        .collection("Yanitlar")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({
          "timeStamp": DateTime.now().millisecondsSinceEpoch,
          "cevaplar": List.filled(model.cevaplar.length, ""),
        });
    SetOptions(merge: true);
  }

  void toggleAnswer(int index, String item) {
    if (cevaplar[index] == item) {
      cevaplar[index] = "";
    } else {
      cevaplar[index] = item;
    }
  }

  void handleFinishTest(BuildContext context) {
    if (isConnected.value) {
      setData();
    } else {
      showAlertDialog(
        "İnternet bağlantınızı açın!",
        "Sınavı bitirmek istiyor iseniz internet bağlantınızı açınız",
      );
    }
  }

  void startTest() {
    selection.value = 1;
  }

  void showAlertDialog(String title, String desc) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "MontserratBold",
                ),
              ),
              SizedBox(height: 10),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Text(
                    "Tamam",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
